//
//  CSJAudioData.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/5.
//

#include "CSJAudioData.hpp"

CSJAudioData::CSJAudioData() {
    sample_num_ = 0;
    channel_ = 0;
    sample_rate_ = 0;
    duration_ = 0;
    time_stamp_ = 0;
    data_ = nullptr;
}

CSJAudioData::CSJAudioData(int sample_num,
                           int channel,
                           int sample_rate,
                           double duration,
                           int size,
                           double time_stamp,
                           uint8_t* data)
    :sample_num_(sample_num),
     channel_(channel),
     sample_rate_(sample_rate),
     duration_(duration),
     size_(size),
     time_stamp_(time_stamp),
     data_(data) {
    
}

CSJAudioData::~CSJAudioData() {
    if (data_) {
        delete []data_;
        data_ = nullptr;
    }
}

CSJAudioData::CSJAudioData(CSJAudioData &&audioData) {
    if (audioData.data_) {
        data_ = audioData.data_;
        audioData.data_ = nullptr;
    }
    
    sample_num_ = audioData.sample_num_;
    channel_ = audioData.channel_;
    sample_rate_ = audioData.sample_rate_;
    duration_ = audioData.duration_;
    size_ = audioData.size_;
    time_stamp_ = audioData.time_stamp_;
}

CSJAudioData& CSJAudioData::operator=(CSJAudioData &&audioData) {
    if (audioData.data_) {
        data_ = audioData.data_;
        audioData.data_ = nullptr;
    }
    
    sample_num_ = audioData.sample_num_;
    channel_ = audioData.channel_;
    sample_rate_ = audioData.sample_rate_;
    duration_ = audioData.duration_;
    size_ = audioData.size_;
    time_stamp_ = audioData.time_stamp_;
    
    return *this;
}
