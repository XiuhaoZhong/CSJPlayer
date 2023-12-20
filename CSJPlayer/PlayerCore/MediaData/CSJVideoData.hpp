//
//  CSJVideoData.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/1.
//

#ifndef CSJVideoData_hpp
#define CSJVideoData_hpp

#include <stdio.h>
#include <stdint.h>

/*
 * This class contains all the data of image
 * which will be render to the screen.
 *
 */
class CSJVideoData {
public:
    CSJVideoData();
    CSJVideoData(int width, int height, int frame_rate, double frame_pts, double timeStamp,  double duration, uint8_t *data);
    ~CSJVideoData();
    
    CSJVideoData(CSJVideoData& videoData) = delete;
    CSJVideoData(CSJVideoData&& videoData);
    
    CSJVideoData& operator=(CSJVideoData &&videoData);
    
    int getWidth() const {
        return width_;
    }
    
    int getHeight() const {
        return height_;
    }
    
    int getFrameRate() const {
        return frame_rate_;
    }
    
    double getFramePts() const {
        return frame_pts_;
    }
    
    double getTimestamp() const {
        return time_stamp_;
    }
    
    double getDuration() const {
        return duration_;
    }
    
    uint8_t *getData() const {
        return data_;
    }
    
private:
    int     width_;         // video width;
    int     height_;        // video height;
    int     frame_rate_;    // video frameRate;
    double  frame_pts_;     // video frame pts;
    double  time_stamp_;    // video tiem stamp;
    double  duration_;      // video frame duration;
    
    uint8_t *data_;         // frame data;
};

#endif /* CSJVideoData_hpp */
