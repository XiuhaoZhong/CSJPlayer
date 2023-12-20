//
//  CSJAudioConverter.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/26.
//

#ifndef CSJAudioConverter_hpp
#define CSJAudioConverter_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "libavutil/samplefmt.h"
#include "libswresample/swresample.h"
#ifdef __cplusplus
}
#endif

class CSJAudioConverter {
public:
    CSJAudioConverter();
    ~CSJAudioConverter();
    
    uint8_t* FLTP2S16(AVFrame *inFrame, int64_t* dataSize);
    
    bool initConverter(int in_nb_sample,
                       int out_nb_sample,
                       int in_sample_rate,
                       int out_sample_rate,
                       AVChannelLayout *in_channel_layout,
                       AVChannelLayout *out_channel_layout,
                       AVSampleFormat in_sample_fmt,
                       AVSampleFormat out_sample_fmt);
    
private:
    int in_nb_samples_;
    int out_nb_samples_;
    
    int in_channel_counts_;
    int out_channel_counts_;
    
    int in_sample_rate_;
    int out_sample_rate_;
    
    int64_t in_ch_layout_;
    int64_t out_ch_layout_;
    
    AVSampleFormat in_sample_fmt_;
    AVSampleFormat out_sample_fmt_;
    
    SwrContext  *swr_context_;
    int         out_size_;
    uint8_t     *outData_;
    
};

#endif /* CSJAudioConverter_hpp */
