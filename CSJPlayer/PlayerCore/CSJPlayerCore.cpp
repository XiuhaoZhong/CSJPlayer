//
//  CSJPlayerInfo.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/21.
//

#include "CSJPlayerCore.hpp"

#ifdef __cplusplus
extern "C" {
#endif

#include "libavformat/avformat.h"

#ifdef __cplusplus
};
#endif

#include <string>
#include <iostream>
#include <memory.h>

#include "CSJVideoInformation.hpp"
#include "CSJPlayerSyncer.hpp"
#include "CSJMpegDecoder.hpp"

using std::string;

CSJPlayerCore::CSJPlayerCore() {
    status_ = CSJPlayerStatus_None;
    decode_finished_ = false;
    media_decoder_ = std::make_shared<CSJMpegDecoder>();
}

CSJPlayerCore::~CSJPlayerCore() {
    
}

void CSJPlayerCore::decodeFihished() {
    decode_finished_ = true;
}

void CSJPlayerCore::outputFFmepgInputFormats() {
    void *protocols = NULL;
    const char *inputFormats = avio_enum_protocols(&protocols, 0);
    
    std::cout << "FFmpeg supports inputFormats: ";
    std::cout << inputFormats << std::endl;
}

bool CSJPlayerCore::openVideoWithPath(const char *videoPath) {
    // create CSJMpegDecoder and open the videoPath;
    if (!videoPath) {
        std::cout << "[" << __FUNCTION__ << "]" << "can't open a empty file!" << std::endl;
        return false;
    }
    
    bool res = media_decoder_->openFileWithUrl(videoPath);
    if (!res) {
        std::cout << "[" << __FUNCTION__ << "]" << "open file failed!" << std::endl;
        return false;
    }
    
    if (video_infomation_) {
        delete video_infomation_;
        video_infomation_ = nullptr;
    }
    
    // get the basic information of current media file.
    video_infomation_ = new CSJVideoInformation();
    video_infomation_->loadVideoInformation(media_decoder_->getFormatCtx());
    
    // open file success, ready to start play.
    status_ = CSJPlayerStatus_Ready;
    
    return true;
}

void CSJPlayerCore::start() {
    // Decode start.
    // The operation of get image data and
    // audio data are control by top level.
    media_decoder_->startDecode();
    status_ = CSJPlayerStatus_Playing;
}

void CSJPlayerCore::pause() {
    media_decoder_->pauseDecode();
    status_ = CSJPlayerStatus_Pause;
}

void CSJPlayerCore::resume() {
    media_decoder_->resumeDecode();
    status_ = CSJPlayerStatus_Playing;
}

void CSJPlayerCore::stop() {
    media_decoder_->stopDecode();
    status_ = CSJPlayerStatus_Stop;
}

void CSJPlayerCore::seekToTime(double time) {
    media_decoder_->decodeWithSeek(time);
}

CSJVideoData* CSJPlayerCore::getSeekVideoData() {
    CSJVideoData *videoData = media_decoder_->getSeekVideo();
    
    return std::move(videoData);
}

void CSJPlayerCore::closeVideo() {
    if (video_infomation_) {
        delete video_infomation_;
        video_infomation_ = nullptr;
    }
}

CSJVideoData* CSJPlayerCore::getRenderVideoData(int &isFinished) {
    CSJPlayerSyncerPtr syncer = CSJPlayerSyncer::getInstance();
    
    // TODO: 根据当前音频帧的时间戳和时长，来选择最合适的视频帧;
    
    CSJVideoData *videoData = syncer->popVideoData();
    // 默认的休眠时间是当前视频帧的时长;
    double sleepDur = videoData->getDuration();
    
    
//    double curAudioTime = syncer->getCurAudioTimeStamp();
//    double curAudioDur = syncer->getCurAudioDuration();
//
//    double curVideoTime = videoData->getTimestamp();
//    double curVideoDur = videoData->getDuration();
//
//    if (curAudioTime == curVideoTime) {
//        // 音频帧开始时间和视频帧相等，休眠时间取两者中小的一个
//        sleepDur = curAudioDur > curVideoDur ? curVideoDur : curAudioDur;
//    } else if (cur)
    
    
    if (!videoData && decode_finished_) {
        isFinished = 1;
    } else {
        isFinished = 0;
    }
    
    //std::cout << "[time debug] current video frame time: " << videoData->getTimestamp() << ", dur: " << videoData->getDuration() << std::endl;
    
    return videoData;
}

CSJAudioData* CSJPlayerCore::getAudioData(int &isFinished) {
    CSJPlayerSyncerPtr syncer = CSJPlayerSyncer::getInstance();
    
    CSJAudioData *audioData = syncer->popAudioData();
    if (!audioData && decode_finished_) {
        isFinished = 1;
    } else {
        isFinished = 0;
    }
    
    //std::cout << "[time debug] current audio frame time: " << audioData->getTimeStamp() << ", dur: " << audioData->getDuration() << std::endl;
    
    return audioData;
}
