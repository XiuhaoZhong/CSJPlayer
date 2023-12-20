//
//  CSJVideoInformation.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/24.
//

#include "CSJVideoInformation.hpp"

#include <iostream>

#ifdef __cplusplus
extern "C" {
#endif

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"

#ifdef __cplusplus
}
#endif

static void releaseStr(std::string *str) {
    if (str) {
        delete str;
        str = nullptr;
    }
}

CSJVideoInformation::CSJVideoInformation() {
    
}

CSJVideoInformation::~CSJVideoInformation() {
    releaseStr(file_path_);
    releaseStr(format_);
    releaseStr(duration_str_);
    releaseStr(video_format_);
    releaseStr(audio_format_);
}

void CSJVideoInformation::loadVideoInformation(AVFormatContext *formatContext) {
    if (!formatContext) {
        return ;
    }
    
    file_path_ = new std::string(formatContext->url);
    
    // stream numbers;
    stream_numbers_ = formatContext->nb_streams;
    int hours, mins, secs, totalSecs;
    secs = formatContext->duration / 1000000;
    duration_ = secs;
    totalSecs = secs;
    mins = secs / 60;
    secs %= 60;
    hours = mins / 60;
    mins %= 60;
    
    char duration_format[128];
    sprintf(duration_format, "%d:%02d:%02d", hours, mins, secs);
    duration_str_ = new std::string(duration_format);
    std::cout << "format: " << formatContext->streams[0]->codecpar->format << std::endl;
    std::cout << "bit rate: " << formatContext->bit_rate / 1000.0 << std::endl;
    
    const AVInputFormat *informat = formatContext->iformat;
    format_ = new std::string(informat->name);
    
    // traverse streams;
    for (unsigned int i = 0; i < stream_numbers_; i++) {
        AVStream *input_stream = formatContext->streams[i];
        
        // video stream;
        if (input_stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            
            // avg_frame_rate -> AVRational(有理数);
            // avg_frame_rate.num 分子;
            // avg_frame_rate.den 分母;
            frame_rate_ = input_stream->avg_frame_rate.num / input_stream->avg_frame_rate.den;
            
            // 获取流中的编码参数，生成AVCodecParamtes对象;
            AVCodecParameters *codec_par = input_stream->codecpar;
            width_ = codec_par->width;
            height_ = codec_par->height;
            video_average_bit_rate_ = codec_par->bit_rate / 1000000;
            video_size_ = codec_par->bit_rate * totalSecs / (8.0 * 1024 * 1024);
            
            AVCodecContext *avctx_video;
            avctx_video = avcodec_alloc_context3(NULL);
            int ret = avcodec_parameters_to_context(avctx_video, codec_par);
            if (ret < 0) {
                avcodec_free_context(&avctx_video);
                std::cout << "get Video AVCodecContext error!" << std::endl;
                return ;
            }
            
            char buf[128];
            avcodec_string(buf, sizeof(buf), avctx_video, 0);
            // 使用AVCodecParameters得到视频编码方式;
            video_format_ = new std::string(avcodec_get_name((codec_par->codec_id)));
        } else if (input_stream->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            // 生成AVCodecParameters对象;
            AVCodecParameters *codec_par = input_stream->codecpar;
            AVCodecContext *avctx_audio;
            avctx_audio = avcodec_alloc_context3(NULL);
            int ret = avcodec_parameters_to_context(avctx_audio, codec_par);
            if (ret < 0) {
                avcodec_free_context(&avctx_audio);
                std::cout << "get Audio AVCodecContext error!" << std::endl;
                return ;
            }
            
            audio_format_ = new std::string(avcodec_get_name(avctx_audio->codec_id));
            audio_average_bit_rate_ = codec_par->bit_rate / 1000;
            channel_nums_ = codec_par->channels;
            sample_rate_ = codec_par->sample_rate;
            audio_size_ = codec_par->bit_rate * totalSecs / (8.0 * 1024);
        }
    }
    
}
