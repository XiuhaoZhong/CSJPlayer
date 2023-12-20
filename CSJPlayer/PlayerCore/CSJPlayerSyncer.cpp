//
//  CSJPlayerSyncer.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/1.
//

#include "CSJPlayerSyncer.hpp"

#ifdef __cplusplus
extern "C" {
#endif

#include "libavformat/avformat.h"

#ifdef __cplusplus
};
#endif

#include "CSJRingBuffer.h"
#include "CSJPlayerTools.h"

std::shared_ptr<CSJPlayerSyncer> CSJPlayerSyncer::instance_;
static std::once_flag singletonFlag;

std::shared_ptr<CSJPlayerSyncer> CSJPlayerSyncer::getInstance() {
    std::call_once(singletonFlag, [&] {
        instance_ = std::make_shared<CSJPlayerSyncer>();
    });
    return instance_;
}

CSJPlayerSyncer::CSJPlayerSyncer() {
    videoArr_ = new CSJRingBuffer<CSJVideoData>(g_framesNum);
    audioArr_ = new CSJRingBuffer<CSJAudioData>(g_framesNum);
    
    audioArr_fulled_ = false;
}

CSJPlayerSyncer::~CSJPlayerSyncer() {
    
}

void CSJPlayerSyncer::resetSyncer() {
    // in case of a situation that some write thread is blocked at the
    // vdieoArr_ videoArr_not_full_cond_ so that the thread couldn't
    // exit;
    videoArr_not_empty_cond_.notify_one();
    // TODO: audioArr_ will do the same thing.
}

CSJVideoData *CSJPlayerSyncer::popVideoData() {
    std::unique_lock<std::mutex> lock(videoArr_Mutex_);
    //std::lock_guard<std::mutex> lock(videoArr_Mutex_);
    
    if (videoArr_->isEmpty()) {
        std::cout << "[" << __FUNCTION__ << "] " << "video frame is null" << std::endl;
        videoArr_not_empty_cond_.wait(lock);
        //return nullptr;
    }
    
    CSJVideoData *videoData = videoArr_->getReadElement();
    CSJVideoData *rawData = new CSJVideoData(std::move(*videoData));
    
    videoArr_->pop_to_next();
    
    // TODO: notify the videoArr_ is not full;
    if (videoArr_->getFullRate() < 0.5) {
        videoArr_not_full_cond_.notify_one();
    }
    
    return rawData;
}

void CSJPlayerSyncer::pushVideoData(CSJVideoData *videoData) {
    std::unique_lock<std::mutex> lock(videoArr_Mutex_);
    
    if (videoArr_->isFull()) {
        // TODO: wait videoArr has space to save the data;
        
        //std::cout << "[" << __FUNCTION__ << "]" << " video frame queue is full, wait!" << std::endl;
        videoArr_not_full_cond_.wait(lock);
    }
    
    CSJVideoData *saveData = videoArr_->getWriteElement();
    *saveData = std::move(*videoData);
    
    videoArr_->push_to_next();
    // notify videoArr_ is not empty;
    videoArr_not_empty_cond_.notify_one();
}

bool CSJPlayerSyncer::isVideoArrEmpty() {
    std::lock_guard<std::mutex> guard(videoArr_Mutex_);
    
    return false;
}

void CSJPlayerSyncer::pushAudioData(CSJAudioData *audioData) {
    std::unique_lock<std::mutex> lock(audioArr_Mutex_);
    
    if (audioArr_->isFull()) {
        // TODO: wait videoArr has space to save the data;
        //audioArr_fulled_ = true;
        
        //std::cout << "[" << __FUNCTION__ << "]" << " current frame queue is full, wait!" << std::endl;
        audioArr_not_full_cond_.wait(lock);
    }
    
    CSJAudioData *saveData = audioArr_->getWriteElement();
    *saveData = std::move(*audioData);
    
    audioArr_->push_to_next();
    // notify videoArr_ is not empty;
    audioArr_not_empty_cond_.notify_one();
}

CSJAudioData* CSJPlayerSyncer::popAudioData() {
    std::unique_lock<std::mutex> lock(audioArr_Mutex_);
    
    while (audioArr_->isEmpty()) {
        audioArr_not_empty_cond_.wait(lock);
    }
    
    CSJAudioData *audioData = audioArr_->getReadElement();
    CSJAudioData *rawData = new CSJAudioData(std::move(*audioData));
    
    cur_audio_time_stamp_ = rawData->getTimeStamp();
    cur_audio_duration_ = rawData->getDuration();
    
    audioArr_->pop_to_next();
    
    // TODO: notify the videoArr_ is not full;
    if (audioArr_->getFullRate() < 0.5) {
        audioArr_not_full_cond_.notify_one();
    }
    
    return rawData;
}
