//
//  CSJPlayerSyncer.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/1.
//

#ifndef CSJPlayerSyncer_hpp
#define CSJPlayerSyncer_hpp

#include <stdio.h>
#include <memory>
#include <mutex>

#include "CSJVideoData.hpp"
#include "CSJAudioData.hpp"

template<typename T>
class CSJRingBuffer;

/*
 * This class is the producer of video and audio data;
 *
 * current is only response for outptu video data and
 * audio data respectively.
 *
 * the functionality of video and audio data‘s synchronization
 * will be achieved later.
 *
 */
class CSJPlayerSyncer {
public:
    static std::shared_ptr<CSJPlayerSyncer> getInstance();
    
    CSJPlayerSyncer();
    ~CSJPlayerSyncer();
    CSJPlayerSyncer(const CSJPlayerSyncer& syncer) = delete;
    CSJPlayerSyncer(CSJPlayerSyncer&& syncer) = delete;
    
    // clear the decoded data when stop playing;
    void resetSyncer();
    
    /* get a video frame data from the videoArr;
     *
     * If the videoArr_ is empty when render thread wants to get
     * video data, the function will return a nullptr, and the
     * render thread need to deal this situation.
     */
    CSJVideoData *popVideoData();
    // write a video frame in to the videoArr;
    void pushVideoData(CSJVideoData *videoData);
    
    CSJAudioData *popAudioData();
    void pushAudioData(CSJAudioData *audioData);
    // check the videoArr empty or not;
    bool isVideoArrEmpty();
    
    double getCurAudioTimeStamp() const {
        return cur_audio_time_stamp_;
    }
    
    double getCurAudioDuration() const {
        return cur_audio_duration_;
    }
    
private:
    void clearData();
private:
    CSJRingBuffer<CSJVideoData> *videoArr_;
    std::mutex                  videoArr_Mutex_;
    std::condition_variable     videoArr_not_full_cond_;
    std::condition_variable     videoArr_not_empty_cond_;
    
    CSJRingBuffer<CSJAudioData> *audioArr_;
    std::mutex                  audioArr_Mutex_;
    std::condition_variable     audioArr_not_full_cond_;
    std::condition_variable     audioArr_not_empty_cond_;
    bool                        audioArr_fulled_;           // 音频数据队列是否满过;
    double                      cur_audio_time_stamp_;      // 当前播放的音频的起始时间;
    double                      cur_audio_duration_;        // 当前正在播放音频帧的时长;
    
    static CSJPlayerSyncer *syncer_;
    static std::shared_ptr<CSJPlayerSyncer> instance_;
};

using CSJPlayerSyncerPtr = std::shared_ptr<CSJPlayerSyncer>;

#endif /* CSJPlayerSyncer_hpp */
