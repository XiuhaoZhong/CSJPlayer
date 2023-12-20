//
//  CSJVideoData.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/1.
//

#include "CSJVideoData.hpp"

CSJVideoData::CSJVideoData() {
    width_ = 0;
    height_ = 0;
    frame_rate_ = 0;
    frame_pts_ = 0;
    data_ = nullptr;
}

CSJVideoData::CSJVideoData(int width, int height, int frame_rate, double frame_pts, double time_stamp, double duration, uint8_t *data)
    : width_(width),
      height_(height),
      frame_rate_(frame_rate),
      frame_pts_(frame_pts),
      time_stamp_(time_stamp),
      duration_(duration),
      data_(data) {
}

CSJVideoData::~CSJVideoData() {
    if (data_) {
        delete []data_;
        data_ = nullptr;
    }
}

CSJVideoData::CSJVideoData(CSJVideoData&& data) {
    this->width_ = data.width_;
    this->height_ = data.height_;
    this->frame_rate_ = data.frame_rate_;
    this->frame_pts_ = data.frame_pts_;
    this->time_stamp_ = data.time_stamp_;
    this->duration_ = data.duration_;
    if (data.data_) {
        this->data_ = data.data_;
        data.data_ = nullptr;
    }
}

CSJVideoData& CSJVideoData::operator=(CSJVideoData &&videoData) {
    this->width_ = videoData.width_;
    this->height_ = videoData.height_;
    this->frame_rate_ = videoData.frame_rate_;
    this->frame_pts_ = videoData.frame_pts_;
    this->time_stamp_ = videoData.time_stamp_;
    this->duration_ = videoData.duration_;
    if (videoData.data_) {
        this->data_ = videoData.data_;
        videoData.data_ = nullptr;
    }
    
    return *this;
}
