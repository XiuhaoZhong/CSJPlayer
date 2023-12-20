//
//  CSJMpegDecoder.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/5.
//

#include "CSJMpegDecoder.hpp"

#include <iostream>
#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "libavfilter/avfilter.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"

#ifdef __cplusplus
};
#endif

#include "CSJAudioConverter.hpp"
#include "CSJPlayerSyncer.hpp"
#include "CSJRingBuffer.h"
#include "CSJVideoData.hpp"
#include "CSJAudioData.hpp"
#include "libyuv.h"

using namespace std::chrono_literals;

CSJMpegDecoder::CSJMpegDecoder() {
    decoder_pause_lock_ = std::unique_lock<std::mutex>(decoder_pause_mutex_);
    queues_empty_lock_ = std::unique_lock<std::mutex>(queues_empty_mutex_);
    
    decoder_delegate_ = nullptr;
}

CSJMpegDecoder::~CSJMpegDecoder() {
    if (decoder_delegate_) {
        decoder_delegate_ = nullptr;
    }
}

void CSJMpegDecoder::prepareForOpenFile() {
    if (video_packet_queue_ || audio_packet_queue_) {
        clearPacketQueues();
    }
    
    video_packet_queue_ = new CSJRingBuffer<AVPacket>(g_packetsNum);
    audio_packet_queue_ = new CSJRingBuffer<AVPacket>(g_packetsNum);
    
    if (format_ctx_) {
        avformat_free_context(format_ctx_);
    }
    
    // set some status;
    stop_ = true;
    pause_ = false;
    decode_is_ready_ = false;
    
    resetThreadFinish();
    
    originFilel_ = fopen("originl.pcm", "w+");
    if (!originFilel_) {
        std::cout << "[CSJMpegDecoder] can't create music file!" << std::endl;
    }
    
    originFiler_ = fopen("originr.pcm", "w+");
    if (!originFiler_) {
        std::cout << "[CSJMpegDecoder] can't create music file!" << std::endl;
    }
}

bool CSJMpegDecoder::openFileWithUrl(const char * url) {
    if (!url) {
        std::cout << "[CSJMpegDecoder] can't open unexist file!" << std::endl;
        return false;
    }
    
    prepareForOpenFile();
    
    format_ctx_ = avformat_alloc_context();
    format_ctx_->probesize = 50 * 1024;
    format_ctx_->max_analyze_duration = 75000;
    
    int res = avformat_open_input(&format_ctx_, url, NULL, NULL);
    if (res != 0) {
        // open media file error;
        return false;
    }
    
    res = avformat_find_stream_info(format_ctx_, NULL);
    if (res < 0) {
        // find strem error;
        return false;
    }
    
    av_dump_format(format_ctx_, -1, url, 0);
    
    // 解码上下文是否分配成功;
    bool decodeCtxAllocRes = false;
    
    // 获取对应流的索引号;
    int videoStreamIdx = -1;
    int audioStreamIdx = -1;
    
    for (int i = 0; i < format_ctx_->nb_streams; i++) {
        if (format_ctx_->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamIdx = i;
        }
        
        if (format_ctx_->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamIdx = i;
        }
    }
    
    if (videoStreamIdx == -1) {
        // TODO: log 视频流索引异常;
        decodeCtxAllocRes |= false;
    } else {
        // 获取视频流和音频流的解码器;
        video_codec_ctx_ = avcodec_alloc_context3(NULL);
        if (avcodec_parameters_to_context(video_codec_ctx_, format_ctx_->streams[videoStreamIdx]->codecpar) < 0) {
            // TODO: log 获取视频解码器失败;
            return -1;
        }
        if (videoStreamIdx != -1 && !video_codec_ctx_->codec) {
            video_codec_ctx_->codec = avcodec_find_decoder(video_codec_ctx_->codec_id);
        }
        
        video_stream_index_ = videoStreamIdx;
        decodeCtxAllocRes |= true;
    }
    
    if (audioStreamIdx == -1) {
        // TODO: log 音频流索引异常;
        decodeCtxAllocRes |= false;
    } else {
        audio_stream_index_ = audioStreamIdx;
        audio_codec_ctx_ = avcodec_alloc_context3(NULL);
        if (avcodec_parameters_to_context(audio_codec_ctx_, format_ctx_->streams[audioStreamIdx]->codecpar) < 0) {
            // TODO: log 获取音频解码器失败;
            return -1;
        }
        // 设置一下这两个属性，并不能让音频解码成相应的格式，至少aac和mp3不行;
//        m_pAudioCodecCtx->request_sample_fmt = AV_SAMPLE_FMT_S16;
//        m_pAudioCodecCtx->request_channel_layout = m_vAudioChannelLayout;
        if (!audio_codec_ctx_->codec) {
            audio_codec_ctx_->codec = avcodec_find_decoder(audio_codec_ctx_->codec_id);
        }
        
        // 根据音频解码器的属性创建音频转换器;
        this->audio_sample_rate_ = this->audio_codec_ctx_->sample_rate;
        decodeCtxAllocRes |= true;
    }
    
    if (!decodeCtxAllocRes) {
        // TODO: 音频和视频解码Ctx都创建失败，返回
        return -1;
    }
    
    decode_is_ready_ = true;
    
    return true;
}

void CSJMpegDecoder::startDecode() {
    if (!decode_is_ready_) {
        std::cout << "[CSJMpegDecoder] the decoder can't be ready to decode" << std::endl;
        return ;
    }
    
    if (!stop_) {
        std::cout << "[CSJMpegDecoder] decoder is working now!" << std::endl;
        return ;
    }
    
    stop_ = false;
    pause_ = false;
    
    // start reading packet in to buffer;
    read_thread_ = std::thread(&CSJMpegDecoder::read_packet, this);
    
    // start decoding video packets;
    video_decode_thread_ = std::thread(&CSJMpegDecoder::video_decoder_func, this);

    // start decoding audio packets;
    audio_decode_thread_ = std::thread(&CSJMpegDecoder::audio_decoder_func, this);
    
    std::cout << "[CSJMpegDecoder] decoding is started!" << std::endl;
}

void CSJMpegDecoder::pauseDecode() {
    if (originFilel_) {
        fclose(originFilel_);
        originFilel_ = NULL;
    }
    
    if (originFiler_) {
        fclose(originFiler_);
        originFiler_ = NULL;
    }
    
    pause_ = true;
}

void CSJMpegDecoder::resumeDecode() {
    pause_ = false;
    decoder_pause_cond_.notify_all();
}

void CSJMpegDecoder::stopDecode() {
    stop_ = true;
    pause_ = false;
    
//    read_thread_.join();
//    video_decode_thread_.join();
//    audio_decode_thread_.join();
}

void CSJMpegDecoder::decodeWithSeek(double seekPos) {
    if (!format_ctx_) {
        return ;
    }
    
    // TODO: 根据seekPos的值，从时间转换成以当前流时间基为基础位置，再执行seek操作
    
    //double duration = decodedFrame->duration * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
    
    int64_t timeStamp = seekPos / av_q2d(format_ctx_->streams[video_stream_index_]->time_base); //* AV_TIME_BASE; /
    
    std::cout << "current seek to " << seekPos << "s, timestamp is " << timeStamp << std::endl;
    
    int64_t seek_min = timeStamp - 2;
    int64_t seek_max = timeStamp + 2;
    
    avformat_seek_file(format_ctx_, -1, seek_min, seekPos, seek_max, AVSEEK_FLAG_BYTE);
}

CSJVideoData* CSJMpegDecoder::getSeekVideo() {
    CSJVideoData *videoData = nullptr;
    
    AVPacket *pkt = av_packet_alloc();
    
    av_read_frame(format_ctx_, pkt);
    while (pkt->stream_index != video_stream_index_) {
        av_read_frame(format_ctx_, pkt);
    }
    
    videoData = decode_video_packet(pkt);
    av_packet_free(&pkt);
    
    return std::move(videoData);
}

void CSJMpegDecoder::clearPacketQueues() {
    if (audio_packet_queue_) {
        for (int i = 0; i < g_packetsNum; i++) {
            AVPacket *packet = audio_packet_queue_->getElemntByIndex(i);
            av_packet_free(&packet);
        }
        
        delete audio_packet_queue_;
        audio_packet_queue_ = nullptr;
    }
    
    if (video_packet_queue_) {
        for (int i = 0; i < g_packetsNum; i++) {
            AVPacket *packet = video_packet_queue_->getElemntByIndex(i);
            av_packet_free(&packet);
        }
        
        delete video_packet_queue_;
        video_packet_queue_ = nullptr;
    }
}

void CSJMpegDecoder::put_packet_into_queue(CSJRingBuffer<AVPacket> *queue,
                                           std::mutex &mtx,
                                           std::condition_variable& cond,
                                           AVPacket *inPacket) {
    if (!inPacket) {
        //std::cout << "[" << __FUNCTION__ << "]" << " inPacket is null!" << std::endl;
        return ;
    }

    std::unique_lock<std::mutex> uLock(video_packet_queue_mutex_);
    
    if (queue->isFull()) {
        //std::cout << "[" << __FUNCTION__ << "]" << " current packet queue is full, wait!" << std::endl;
        cond.wait(uLock);
    }
    
    AVPacket *curPacket = queue->getWriteElement();
    av_packet_move_ref(curPacket, inPacket);
    queue->push_to_next();
}

void CSJMpegDecoder::get_packet_from_queue(CSJRingBuffer<AVPacket> *queue,
                                           std::mutex &mtx,
                                           std::condition_variable& cond,
                                           AVPacket *outPacket) {
    if (!outPacket) {
        return ;
    }
    
    std::unique_lock<std::mutex> uLock(video_packet_queue_mutex_);
    if (queue->isEmpty()) {
        cond.wait(uLock);
    }
    
    AVPacket *curPacket = queue->getReadElement();
    av_packet_move_ref(outPacket, curPacket);
    queue->pop_to_next();
}

bool CSJMpegDecoder::queueAreFull() {
    if (video_packet_queue_->isFull() || audio_packet_queue_->isFull()) {
        return true;
    }
    
    return false;
}

void CSJMpegDecoder::NotifyContinueReadIfNeeded() {
    if (video_packet_queue_->getFullRate() <= 0.5 ||
        audio_packet_queue_->getFullRate() <= 0.5) {
        queues_empty_cond_.notify_one();
    }
}

void CSJMpegDecoder::read_packet() {
    int ret = avcodec_is_open(video_codec_ctx_);
    if (ret <= 0) {
        ret = avcodec_open2(video_codec_ctx_, video_codec_ctx_->codec, NULL);
        if (ret < 0) {
            std::cout << "[" << __FUNCTION__ << "]" << "video codec open error!" << std::endl;
        }
    }
    
    ret = avcodec_is_open(audio_codec_ctx_);
    if (ret <= 0) {
        ret = avcodec_open2(audio_codec_ctx_, audio_codec_ctx_->codec, NULL);
        if (ret < 0) {
            std::cout << "[" << __FUNCTION__ << "]" << "audio codec open error!" << std::endl;
        }
    }
    
    if (!format_ctx_) {
        std::cout << "[ " << __FUNCTION__ << "]" << "AVFormatContext isn't initialized!" << std::endl;
        return ;
    }
    
    AVPacket *packet = av_packet_alloc();
    while (1) {
        if (stop_) {
            break;
        }
        
        if (pause_) {
            decoder_pause_cond_.wait(decoder_pause_lock_);
        }
        
        int ret = av_read_frame(format_ctx_, packet);
        if (ret < 0) {
//            if (ret == AVERROR_EOF) {
//                std::cout << "[ " << __FUNCTION__ << "]" << "read file done!" << std::endl;
//                // rearch the end of the file, put a empty packet into packet queue;
//                AVPacket *emptyPacket = av_packet_alloc();
//                if (video_stream_index_ >= 0) {
//                    put_packet_into_queue(video_packet_queue_,
//                                          video_packet_queue_mutex_,
//                                          video_packet_queue_not_full_,
//                                          emptyPacket);
//                }
//
//                if (audio_stream_index_ >= 0) {
//                    put_packet_into_queue(audio_packet_queue_,
//                                          audio_packet_queue_mutex_,
//                                          audio_packet_queue_not_full_,
//                                          emptyPacket);
//                }
//            }
            
            break;
        }
        
        // TODO: timestamp checking.
        // when read a packet, needs to check the packet's timestamp is
        // in the spcify range or not, if the timestamp out of the range, should
        // abandon current packet. but now, we don't check the timestamp.
        
        if (packet->stream_index == video_stream_index_) {
            put_packet_into_queue(video_packet_queue_,
                                  video_packet_queue_mutex_,
                                  video_packet_queue_not_full_,
                                  packet);
            video_packet_queue_not_empty_.notify_one();
//            decode_video_pkt(packet);
        } else if (packet->stream_index == audio_stream_index_) {
            put_packet_into_queue(audio_packet_queue_,
                                  audio_packet_queue_mutex_,
                                  audio_packet_queue_not_full_,
                                  packet);
            audio_packet_queue_not_empty_.notify_one();
            av_packet_unref(packet);
//            decode_audio_pkt(packet);
        } else {
            // I only care the video and audio streams, other stream not.
            av_packet_unref(packet);
        }
        
        av_packet_unref(packet);
    }
    
    av_packet_free(&packet);
}

CSJVideoData* CSJMpegDecoder::decode_video_packet(AVPacket *packet) {
    AVFrame *decodedFrame = av_frame_alloc();
    CSJVideoData *videoData = nullptr;
    
    // 视频数据解码操作;
    int ret = avcodec_send_packet(video_codec_ctx_, packet);
    if (ret < 0) {
        if (ret == AVERROR_EOF) {
            std::cout << "[" << __FUNCTION__ << "]" << "video docode complete!" << std::endl;
        } else if (ret == AVERROR(EINVAL)) {
            std::cout << "[" << __FUNCTION__ << "]" << "video decoder isn't open!" << std::endl;
        } else {
            std::cout << "[" << __FUNCTION__ << "]" << "video audio data error!" << std::endl;
        }
        
        av_frame_free(&decodedFrame);
        return videoData;
    }
    
    ret = avcodec_receive_frame(video_codec_ctx_, decodedFrame);
    if (ret < 0) {
        if (ret == AVERROR_EOF) {
            std::cout << "[" << __FUNCTION__ << "]" << "has received all audio data!" << std::endl;
        } else {
            std::cout << "[" << __FUNCTION__ << "]" << "receive audio data error!" << std::endl;
        }
        
        av_frame_free(&decodedFrame);
        return videoData;
    }
    
    int width = decodedFrame->width;
    int height = decodedFrame->height;
    if (width > 0 && height > 0) {
        // YUV 420, convert video data with OpenGL fragment shader;
        uint8_t *imageData = new uint8_t[width * height * 3 / 2];
        
        memcpy(imageData, decodedFrame->buf[0]->data, width * height);
        memcpy(imageData + width * height, decodedFrame->buf[1]->data, width * height / 4);
        memcpy(imageData + width * height * 5 / 4, decodedFrame->buf[2]->data, width * height / 4);
        
        // convert to rgb with libyuv;
        //uint8_t *imageData = new uint8_t[width * height * 3];
        //libyuv::I420ToRGB24(decodedFrame->data[0], width, decodedFrame->data[1], width / 2, decodedFrame->data[2], width / 2, imageData, width * 3, width, height);
        
        double duration = decodedFrame->duration * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
        double timestamp = decodedFrame->pts * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
        videoData = new CSJVideoData(width, height, 0, timestamp, timestamp, duration, imageData);
    }
    
    av_frame_free(&decodedFrame);
    return videoData;
}

void CSJMpegDecoder::decode_video_pkt(AVPacket *packet) {
    AVFrame *decodedFrame = av_frame_alloc();
    
    // 视频数据解码操作;
    int ret = avcodec_send_packet(video_codec_ctx_, packet);
    if (ret < 0) {
        if (ret == AVERROR_EOF) {
            std::cout << "[" << __FUNCTION__ << "]" << "video docode complete!" << std::endl;
        } else if (ret == AVERROR(EINVAL)) {
            std::cout << "[" << __FUNCTION__ << "]" << "video decoder isn't open!" << std::endl;
        } else {
            std::cout << "[" << __FUNCTION__ << "]" << "video audio data error!" << std::endl;
        }
        
        av_frame_free(&decodedFrame);
        return ;
    }
    
    ret = avcodec_receive_frame(video_codec_ctx_, decodedFrame);
    if (ret < 0) {
        if (ret == AVERROR_EOF) {
            std::cout << "[" << __FUNCTION__ << "]" << "has received all audio data!" << std::endl;
        } else {
            std::cout << "[" << __FUNCTION__ << "]" << "receive audio data error!" << std::endl;
        }
        
        av_frame_free(&decodedFrame);
        return ;
    }
    
    int width = decodedFrame->width;
    int height = decodedFrame->height;
    if (width > 0 && height > 0) {
        // YUV 420, convert video data with OpenGL fragment shader;
        uint8_t *imageData = new uint8_t[width * height * 3 / 2];
        
        memcpy(imageData, decodedFrame->buf[0]->data, width * height);
        memcpy(imageData + width * height, decodedFrame->buf[1]->data, width * height / 4);
        memcpy(imageData + width * height * 5 / 4, decodedFrame->buf[2]->data, width * height / 4);
        
        // convert to rgb with libyuv;
        //uint8_t *imageData = new uint8_t[width * height * 3];
        //libyuv::I420ToRGB24(decodedFrame->data[0], width, decodedFrame->data[1], width / 2, decodedFrame->data[2], width / 2, imageData, width * 3, width, height);
        
        double duration = decodedFrame->duration * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
        double timestamp = decodedFrame->pts * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
        CSJVideoData videoData(width, height, 0, timestamp, timestamp, duration, imageData);
        CSJPlayerSyncer::getInstance()->pushVideoData(&videoData);
    }
    
    av_frame_free(&decodedFrame);
}

void CSJMpegDecoder::video_decoder_func() {
    int ret = avcodec_is_open(video_codec_ctx_);
    if (ret <= 0) {
        ret = avcodec_open2(video_codec_ctx_, video_codec_ctx_->codec, NULL);
        if (ret < 0) {
            std::cout << "[" << __FUNCTION__ << "]" << "video codec open error!" << std::endl;
        }
    }
    
    AVPacket *packet = av_packet_alloc();
    AVFrame *decodedFrame = av_frame_alloc();
    
    CSJPlayerSyncerPtr syncer = CSJPlayerSyncer::getInstance();
    while (1) {
        if (stop_) {
            break;
        }
        
        if (pause_) {
            decoder_pause_cond_.wait(decoder_pause_lock_);
        }
        
        get_packet_from_queue(video_packet_queue_,
                              video_packet_queue_mutex_,
                              video_packet_queue_not_empty_,
                              packet);
        if (video_packet_queue_->getFullRate() <= 0.5) {
            video_packet_queue_not_full_.notify_one();
        }
        
        if (!packet->data) {
            std::cout << "[" << __FUNCTION__ << "]" << "read a null video packet" << std::endl;
            continue;;
        }
        
        // 视频数据解码操作;
        ret = avcodec_send_packet(video_codec_ctx_, packet);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                std::cout << "[" << __FUNCTION__ << "]" << "video docode complete!" << std::endl;
                break;
            } else if (ret == AVERROR(EINVAL)) {
                std::cout << "[" << __FUNCTION__ << "]" << "video decoder isn't open!" << std::endl;
            } else {
                std::cout << "[" << __FUNCTION__ << "]" << "video audio data error!" << std::endl;
            }
            
            continue;
        }
        
        ret = avcodec_receive_frame(video_codec_ctx_, decodedFrame);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                std::cout << "[" << __FUNCTION__ << "]" << "has received all audio data!" << std::endl;
                break;
            } else {
                std::cout << "[" << __FUNCTION__ << "]" << "receive audio data error!" << std::endl;
            }
            
            continue;
        }
        
        int width = decodedFrame->width;
        int height = decodedFrame->height;
        if (width > 0 && height > 0) {
            // YUV 420, convert video data with OpenGL fragment shader;
            uint8_t *imageData = new uint8_t[width * height * 3 / 2];
            
            memcpy(imageData, decodedFrame->buf[0]->data, width * height);
            memcpy(imageData + width * height, decodedFrame->buf[1]->data, width * height / 4);
            memcpy(imageData + width * height * 5 / 4, decodedFrame->buf[2]->data, width * height / 4);
            
            // convert to rgb with libyuv;
            //uint8_t *imageData = new uint8_t[width * height * 3];
            //libyuv::I420ToRGB24(decodedFrame->data[0], width, decodedFrame->data[1], width / 2, decodedFrame->data[2], width / 2, imageData, width * 3, width, height);
            
            double duration = decodedFrame->duration * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
            double timestamp = decodedFrame->pts * av_q2d(format_ctx_->streams[video_stream_index_]->time_base);
            CSJVideoData videoData(width, height, 0, timestamp, timestamp, duration, imageData);
            syncer->pushVideoData(&videoData);
        }
    }
    
    av_frame_free(&decodedFrame);
    av_packet_free(&packet);
}

void CSJMpegDecoder::decode_audio_pkt(AVPacket *packet) {
    AVFrame *decodedFrame = av_frame_alloc();
    
    if (!packet->data) {
        std::cout << "[ " << __FUNCTION__ << "]" << "read a null video packet" << std::endl;
        return ;
    }
    
    // 音频数据解码操作;
    int ret = avcodec_send_packet(audio_codec_ctx_, packet);
    if (ret < 0) {
        if (ret == AVERROR_EOF) {
            std::cout << "[" << __FUNCTION__ << "]" << "audio docode complete!" << std::endl;
        } else if (ret == EINVAL) {
            std::cout << "[" << __FUNCTION__ << "]" << "audio decoder isn't open!" << std::endl;
        } else {
            std::cout << "[" << __FUNCTION__ << "]" << "decode audio data error!" << std::endl;
        }
        
        return ;
    }
    
    ret = avcodec_receive_frame(audio_codec_ctx_, decodedFrame);
    if (ret < 0) {
        if (ret == AVERROR_EOF) {
            std::cout << "[" << __FUNCTION__ << "]" << "has received all audio data!" << std::endl;
        } else {
            std::cout << "[" << __FUNCTION__ << "]" << "receive audio data error!" << std::endl;
        }
        
        return ;
    }
    
#if 0
    const char* fmtString = av_get_sample_fmt_name(AV_SAMPLE_FMT_FLTP);
    std::cout << "current audio fmt: " << fmtString << std::endl;
    
    int bits = av_get_bytes_per_sample(AV_SAMPLE_FMT_FLTP);
    std::cout << "current sample bytes: " << bits << std::endl;
    
    int totalBytes = av_samples_get_buffer_size(decodedFrame->linesize, decodedFrame->channels, decodedFrame->nb_samples, AV_SAMPLE_FMT_FLTP, 0);
    std::cout << "current total bytes: " << totalBytes << std::endl;
#endif
    if (decodedFrame->format == AV_SAMPLE_FMT_FLTP) {
        if (!audio_converter_) {
            audio_converter_ = new CSJAudioConverter();
        }
    }
    
    double timestamp = decodedFrame->pts * av_q2d(format_ctx_->streams[audio_stream_index_]->time_base);
    double duration = decodedFrame->duration * av_q2d(format_ctx_->streams[audio_stream_index_]->time_base);
    if (audio_converter_) {
        int64_t converted_size = 0;
        uint8_t *convert_data = audio_converter_->FLTP2S16(decodedFrame, &converted_size);
        if (!convert_data) {
            std::cout << "[" << __FUNCTION__ << "]" << " audio convert failed!" << std::endl;
        }
        
        uint8_t *data = new uint8_t[converted_size];
        memcpy(data, convert_data, converted_size);
        CSJAudioData audioData(decodedFrame->nb_samples,
                               decodedFrame->ch_layout.nb_channels,
                               decodedFrame->sample_rate,
                               duration,
                               converted_size,
                               timestamp,
                               data);
        
        CSJPlayerSyncer::getInstance()->pushAudioData(&audioData);
    } else {
        int length = decodedFrame->linesize[0];
        uint8_t *data = new uint8_t[length];
        memcpy(data, decodedFrame->data[0], length / 2);
        memcpy(data + length / 2, decodedFrame->data[1], length / 2);
        CSJAudioData audioData(decodedFrame->nb_samples,
                               decodedFrame->ch_layout.nb_channels,
                               decodedFrame->sample_rate,
                               duration,
                               length,
                               timestamp,
                               data);
        
        CSJPlayerSyncer::getInstance()->pushAudioData(&audioData);
    }

    av_frame_free(&decodedFrame);
}

void CSJMpegDecoder::audio_decoder_func() {
    int ret = avcodec_is_open(audio_codec_ctx_);
    if (ret <= 0) {
        ret = avcodec_open2(audio_codec_ctx_, audio_codec_ctx_->codec, NULL);
        if (ret < 0) {
            std::cout << "[" << __FUNCTION__ << "]" << "audio codec open error!" << std::endl;
        }
    }
    
    AVCodecParameters *parameters = avcodec_parameters_alloc();
    avcodec_parameters_copy(parameters, format_ctx_->streams[audio_stream_index_]->codecpar);
    
    AVPacket *packet = av_packet_alloc();
    AVFrame *decodedFrame = av_frame_alloc();
    
    CSJPlayerSyncerPtr syncer = CSJPlayerSyncer::getInstance();
    while (1) {
        if (stop_) {
            break;
        }
        
        if (pause_) {
            decoder_pause_cond_.wait(decoder_pause_lock_);
        }
        
        get_packet_from_queue(audio_packet_queue_,
                              audio_packet_queue_mutex_,
                              audio_packet_queue_not_empty_,
                              packet);
        if (audio_packet_queue_->getFullRate() <= 0.5) {
            audio_packet_queue_not_full_.notify_one();
        }
        
        if (!packet->data) {
            std::cout << "[ " << __FUNCTION__ << "]" << "read a null video packet" << std::endl;
            continue;;
        }
        
        // 音频数据解码操作;
        int ret = avcodec_send_packet(audio_codec_ctx_, packet);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                std::cout << "[" << __FUNCTION__ << "]" << "audio docode complete!" << std::endl;
            } else if (ret == EINVAL) {
                std::cout << "[" << __FUNCTION__ << "]" << "audio decoder isn't open!" << std::endl;
            } else {
                std::cout << "[" << __FUNCTION__ << "]" << "decode audio data error!" << std::endl;
            }
            
            break;
        }
        
        ret = avcodec_receive_frame(audio_codec_ctx_, decodedFrame);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                std::cout << "[" << __FUNCTION__ << "]" << "has received all audio data!" << std::endl;
            } else {
                std::cout << "[" << __FUNCTION__ << "]" << "receive audio data error!" << std::endl;
            }
            
            break;
        }
        
#if 0
        const char* fmtString = av_get_sample_fmt_name(AV_SAMPLE_FMT_FLTP);
        std::cout << "current audio fmt: " << fmtString << std::endl;
        
        int bits = av_get_bytes_per_sample(AV_SAMPLE_FMT_FLTP);
        std::cout << "current sample bytes: " << bits << std::endl;
        
        int totalBytes = av_samples_get_buffer_size(decodedFrame->linesize, decodedFrame->channels, decodedFrame->nb_samples, AV_SAMPLE_FMT_FLTP, 0);
        std::cout << "current total bytes: " << totalBytes << std::endl;
#endif
        if (decodedFrame->format == AV_SAMPLE_FMT_FLTP) {
            if (!audio_converter_) {
                audio_converter_ = new CSJAudioConverter();
            }
        }
        
        double timestamp = decodedFrame->pts * av_q2d(format_ctx_->streams[audio_stream_index_]->time_base);
        if (audio_converter_) {
            int64_t converted_size = 0;
            uint8_t *convert_data = audio_converter_->FLTP2S16(decodedFrame, &converted_size);
            if (!convert_data) {
                std::cout << "[" << __FUNCTION__ << "]" << " audio convert failed!" << std::endl;
            }
            
            uint8_t *data = new uint8_t[converted_size];
            memcpy(data, convert_data, converted_size);
            CSJAudioData audioData(decodedFrame->nb_samples,
                                   decodedFrame->ch_layout.nb_channels,
                                   decodedFrame->sample_rate,
                                   0,
                                   converted_size,
                                   timestamp,
                                   data);
            
            syncer->pushAudioData(&audioData);
        } else {
            int length = decodedFrame->linesize[0];
            uint8_t *data = new uint8_t[length];
            memcpy(data, decodedFrame->data[0], length / 2);
            memcpy(data + length / 2, decodedFrame->data[1], length / 2);
            CSJAudioData audioData(decodedFrame->nb_samples,
                                   decodedFrame->ch_layout.nb_channels,
                                   decodedFrame->sample_rate,
                                   0,
                                   length,
                                   timestamp,
                                   data);
            
            syncer->pushAudioData(&audioData);
        }
    }
    
    av_packet_free(&packet);
    av_frame_free(&decodedFrame);
}

void CSJMpegDecoder::decodeOperationFinished() {
    if (read_finished_ && video_decode_finish_ && audio_decode_finish_) {
        // TODO: notify player core, decoder finished normal;
    }
}

void CSJMpegDecoder::resetThreadFinish() {
    read_finished_ = false;
    video_decode_finish_ = false;
    audio_decode_finish_ = false;
}
