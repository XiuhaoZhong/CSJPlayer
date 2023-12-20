//
//  CSJMpegDecoder.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/5.
//

#ifndef CSJMpegDecoder_hpp
#define CSJMpegDecoder_hpp

#include <stdio.h>
#include <vector>
#include <thread>
#include <mutex>

#ifdef __cplusplus
extern "C" {
#endif

#include "libavformat/avformat.h"

#ifdef __cplusplus
};
#endif

#include "CSJPlayerTools.h"

struct AVCodecContext;
struct AVFormatContext;

template<typename T>
class CSJRingBuffer;

class CSJVideoData;
class CSJAudioData;
class CSJAudioConverter;
class CSJMpegDecoder {
public:
    CSJMpegDecoder();
    ~CSJMpegDecoder();
    
    void setDeocderDelegate(CSJDecoderDelegate *delegate) {
        decoder_delegate_ = delegate;
    }
    
    bool openFileWithUrl(const char *url);
    
    void startDecode();
    void pauseDecode();
    void resumeDecode();
    
    void decodeWithSeek(double seekPos);
    CSJVideoData* getSeekVideo();
    
    /*
     * Marking the stop status before invoking stopDecode function,
     * because there may be threads blocked at the packet_queue or
     * the frame_queue's r/w functions.
     *
     * Then invoke the stop functions to notify relative condition_
     * variables, and the blocked threads will finish safely. Finally,
     * the packet queue or the frame queue could be clear.
     *
     */
    void markStop();
    void stopDecode();
    
    AVFormatContext *getFormatCtx() const {
        return format_ctx_;
    }
    
private:
    /*
     *  Intialize operations before open the media file,
     *  the operations include initializing video_paeckt_queue_
     *  and audio_packet_queue_, creating the format_ctx_ and
     *  so on.
     */
    void prepareForOpenFile();
    
    /*
     * Read packets from the AVFormatContext and write the
     * packet in to the ring buffer according to the packet's
     * stream_index respectively.
     *
     */
    void read_packet();
    /*
     * Decodes the video packets and put the video data into
     * syncer's video data buffer.
     */
    void video_decoder_func();
    
    // invoked by read thread.
    void decode_video_pkt(AVPacket *pkt);
    
    CSJVideoData *decode_video_packet(AVPacket *packet);
    
    /*
     * Decodes the audio packets and put the audio data into
     * syncer's audio data buffer.
     */
    void audio_decoder_func();
    // invoked by read thread;
    void decode_audio_pkt(AVPacket *pkt);
    
    /*
     * Operations on the packet queue, including video packet
     * queue and audio packet queue.
     */
    
    /*
     * Push a packet into packet queue. This function will push
     * the queue's write position to next after the put operation.
     *
     * @param queue     target queue
     * @param inPacket  the packet will be put
     *
     */
    void put_packet_into_queue(CSJRingBuffer<AVPacket> *queue,
                               std::mutex &mtx,
                               std::condition_variable &cond,
                               AVPacket *inPacket);
    
    /*
     * Push a packet into packet queue. This function will push
     * the queue's read position to next after the put operation.
     *
     * @param queue     target queue
     * @param outPacket the packet will be get
     *
     */
    void get_packet_from_queue(CSJRingBuffer<AVPacket> *queue,
                               std::mutex &mtx,
                               std::condition_variable &cond,
                               AVPacket *outPacket);
    
    // Either the video_packet_queue or the audio_packet_queue
    // is full, the function will return true;
    bool queueAreFull();
    
    /*
     * When cosume a video packet or a audio packet, should invoke
     * this function to notify continue read packet if needed. If
     * the read thread is blocked at the queue_full_cond_, then the
     * thread can continue, or nothing will happy except a notify
     * function be invoked.
     */
    void NotifyContinueReadIfNeeded();
    
    // Clear all the packet queues;
    void clearPacketQueues();
    
    /*
     * Decoding to the eof, until the read_thread, video_decoder_thread
     * and audio_decoder_thread exit from eof, it indicates current file
     * is decoded finished. Then notify the playerCore and syncer.
     *
     * If the playing is stopped by the users, this function will not be
     * invoke.
     *
     */
    void decodeOperationFinished();
    
    void resetThreadFinish();
    
private:
    // decoder status;
    bool                         pause_;
    bool                         stop_;
    bool                         decode_is_ready_;              // the preDecode processes are ok;
    
    std::mutex                   decoder_pause_mutex_;
    std::unique_lock<std::mutex> decoder_pause_lock_;
    std::condition_variable      decoder_pause_cond_;
    
    AVFormatContext              *format_ctx_;
    std::thread                  read_thread_;                  // read packet from the ctx;
    bool                         read_finished_;                // read packet finish when eof;
    
    std::mutex                   queues_empty_mutex_;
    std::unique_lock<std::mutex> queues_empty_lock_;
    std::condition_variable      queues_empty_cond_;
    
    std::thread                  video_decode_thread_;
    std::mutex                   video_packet_queue_mutex_;     // control the access of the video_packet_queue_;
    std::condition_variable      video_packet_queue_not_full_;
    std::condition_variable      video_packet_queue_not_empty_;
    // save the video packet read from ctx;
    CSJRingBuffer<AVPacket>      *video_packet_queue_;
    int                          video_stream_index_;
    AVCodecContext               *video_codec_ctx_;
    bool                         video_decode_finish_;          // video decoder exit when eof;
    
    std::thread                  audio_decode_thread_;
    std::mutex                   audio_packet_queue_mutex_;     // control the access of the audio_packet_queue_;
    std::condition_variable      audio_packet_queue_not_full_;
    std::condition_variable      audio_packet_queue_not_empty_;
    // save the video packet read from ctx;
    CSJRingBuffer<AVPacket>      *audio_packet_queue_;
    int                          audio_stream_index_;
    int                          audio_sample_rate_;
    AVCodecContext               *audio_codec_ctx_;
    bool                         audio_decode_finish_;          // audio decoder exit when eof;
    CSJAudioConverter            *audio_converter_;
    
    // The lifecycle of the class implements the CSJDecoderDelegate
    // is longer than the decoder, so there doesn't need to reponse
    // the delete operatoin of the decoder_delegate_;
    CSJDecoderDelegate           *decoder_delegate_;
    
    FILE                         *originFilel_;
    FILE                         *originFiler_;
    
};

#endif /* CSJMpegDecoder_hpp */
