//
//  CSJPlayerInfo.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/21.
//

#ifndef CSJPlayerInfo_hpp
#define CSJPlayerInfo_hpp

#include <stdio.h>
#include <thread>

#ifdef __cplusplus
extern "C" {
#endif

#include "libavformat/avformat.h"

#ifdef __cplusplus
}
#endif

#include "CSJPlayerTools.h"

struct AVFormatContext;
struct AVCodecContext;
class CSJVideoInformation;
class CSJMpegDecoder;
class CSJVideoData;
class CSJAudioData;
class CSJPlayerCore : public CSJDecoderDelegate {
public:
    CSJPlayerCore();
    ~CSJPlayerCore();
    
    void decodeFihished() override;
    
    void outputFFmepgInputFormats();
    
    bool openVideoWithPath(const char* videoPath);
    void closeVideo();
    
    CSJVideoInformation *getMediaInfo() {
        return video_infomation_;
    }
    
    /*
     * Get the videoData will be rendered on the screen.
     *
     * @param out, isFinished: if played to eof the value
     * will be 1;
     *
     */
    CSJVideoData* getRenderVideoData(int &isFinished);
    CSJAudioData* getAudioData(int &isFinished);
    
    void start();
    void pause();
    void resume();
    
    void seekToTime(double time);
    CSJVideoData* getSeekVideoData();
    
    /*
     * Before call this function, caller should stop the data consumers
     * like video render, audio player e.g., then it can avoid the race
     * conditions of decoded data at the stopping operation.
     */
    void stop();
    
    // Get player's status.
    bool isReady() const {
        return status_ == CSJPlayerStatus_Ready;
    }
    
    bool isPlaying() const {
        return status_ == CSJPlayerStatus_Playing;
    }
    
    bool isPause() const {
        return status_ == CSJPlayerStatus_Pause;
    }
    
    bool isStop() const {
        return status_ == CSJPlayerStatus_Stop;
    }
    
private:
    CSJVideoInformation             *video_infomation_;
    std::shared_ptr<CSJMpegDecoder> media_decoder_;
    
    // player status;
    CSJPlayerStatus                 status_;
    bool                            decode_finished_;
};


#endif /* CSJPlayerInfo_hpp */
