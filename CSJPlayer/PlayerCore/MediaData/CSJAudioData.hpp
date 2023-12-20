//
//  CSJAudioData.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/5.
//

#ifndef CSJAudioData_hpp
#define CSJAudioData_hpp

#include <stdio.h>
#include <stdint.h>

class CSJAudioData {
public:
    CSJAudioData();
    CSJAudioData(int sample_num, int channel, int sample_rate, double duration, int size, double time_stamp, uint8_t* data);
    ~CSJAudioData();
    
    CSJAudioData(CSJAudioData& audioData) = delete;
    CSJAudioData(CSJAudioData&& audioData);
    
    CSJAudioData& operator=(CSJAudioData &&audioData);
    
    uint8_t* getData() const {
        return data_;
    }
    
    int getSampleNum() const {
        return sample_num_;
    }
    
    int getChannels() const {
        return channel_;
    }
    
    int getSampleRate() const {
        return sample_rate_;
    }
    
    double getDuration() const {
        return duration_;
    }
    
    double getTimeStamp() const {
        return time_stamp_;
    }
    
    int getSize() const {
        return size_;
    }
    
private:
    uint8_t *data_;
    int     sample_num_;
    int     channel_;
    int     sample_rate_;
    double  duration_;
    int     size_;
    double  time_stamp_;
    
};

#endif /* CSJAudioData_hpp */
