//
//  CSJPlayerTools.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/15.
//

#ifndef CSJPlayerTools_h
#define CSJPlayerTools_h

// video/audio packet queue's number;
const int g_packetsNum = 20;

// video/audio frame queue's number;
const int g_framesNum = 20;

typedef enum playerStaus {
    CSJPlayerStatus_None = 0,
    CSJPlayerStatus_Ready,
    CSJPlayerStatus_Stop,
    CSJPlayerStatus_Playing,
    CSJPlayerStatus_Pause
} CSJPlayerStatus;

// decoder notify player core the decode status;
class CSJDecoderDelegate {
public:
    CSJDecoderDelegate() {}
    virtual ~CSJDecoderDelegate() {}
    
    // decode reaching eof;
    virtual void decodeFihished() = 0;
};


#endif /* CSJPlayerTools_h */
