//
//  CSJVideoInformation.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/24.
//

#ifndef CSJVideoInformation_hpp
#define CSJVideoInformation_hpp

#include <stdio.h>

#include <string>

struct AVFormatContext;
class CSJVideoInformation {
public:
    CSJVideoInformation();
    ~CSJVideoInformation();
    
    void loadVideoInformation(AVFormatContext *formatContext);
    
    std::string* getFilePath() {
        return file_path_;
    }
    
    std::string* getFormat() {
        return format_;
    }
    
    std::string* getDurationStr() {
        return duration_str_;
    }
    
    int getFrameRate() {
        return frame_rate_;
    }
    
    int getVideoAverageBitRate() {
        return video_average_bit_rate_;
    }
    
    int getWidth() {
        return width_;
    }
    
    int getHeight() {
        return height_;
    }
    
    float getVideoSize() {
        return video_size_;
    }
    
    std::string* getVideoFormat() {
        return video_format_;
    }
    
    std::string* getAudioFormat() {
        return audio_format_;
    }
    
    int getAudioAverageBitRate() {
        return audio_average_bit_rate_;
    }
    
    int getChannelNumbers() {
        return channel_nums_;
    }
    
    int getSampleRate() {
        return sample_rate_;
    }
    
    float getAudioSize() {
        return audio_size_;
    }
    
    int getDuration() const {
        return duration_;
    }
    
private:
    std::string     *file_path_;
    std::string     *format_;               // file format;
    std::string     *duration_str_;         // file duration;
    int             duration_;              // file duration with seconds;
    unsigned int    stream_numbers_;        // strema number;
    unsigned int    video_stream_index_;    // video stream index;
    unsigned int    audio_stream_index_;    // audio stream index;
    
    // ************ video informations ************
    int             frame_rate_;
    int             video_average_bit_rate_;
    int             width_;
    int             height_;
    float           video_size_;
    std::string     *video_format_;
    
    // ************ audio informations ************
    std::string     *audio_format_;
    int             audio_average_bit_rate_;
    int             channel_nums_;
    int             sample_rate_;
    int             audio_size_;
};

#endif /* CSJVideoInformation_hpp */
