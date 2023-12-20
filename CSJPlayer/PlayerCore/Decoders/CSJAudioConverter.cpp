//
//  CSJAudioConverter.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/26.
//

#include "CSJAudioConverter.hpp"

#ifdef __cplusplus
extern "C" {
#endif

#include "libavutil/opt.h"
#include "libavutil/samplefmt.h"
#include "libavcodec/avcodec.h"
#include "libavutil/imgutils.h"

#ifdef __cplusplus
}
#endif

CSJAudioConverter::CSJAudioConverter() {
    
}

CSJAudioConverter::~CSJAudioConverter() {
    
}

uint8_t *CSJAudioConverter::FLTP2S16(AVFrame *inFrame, int64_t *dataSize) {
    if (!swr_context_) {
        bool converterInit = initConverter(inFrame->nb_samples,
                                           inFrame->nb_samples,
                                           inFrame->sample_rate,
                                           inFrame->sample_rate,
                                           &inFrame->ch_layout,
                                           &inFrame->ch_layout,
                                           AV_SAMPLE_FMT_FLTP,
                                           AV_SAMPLE_FMT_S16);
        
        if (!converterInit) {
            // audio converter init failed;
            return nullptr;
        }
    }
        
    int out_count = (int64_t)inFrame->nb_samples * inFrame->sample_rate / inFrame->sample_rate;
    int out_size = av_samples_get_buffer_size(NULL,
                                              inFrame->ch_layout.nb_channels,
                                              out_count,
                                              AV_SAMPLE_FMT_S16P,
                                              0);
    if (out_size_ != out_size) {
        if (outData_) {
            av_free(outData_);
        }
        
        out_size_ = out_size;
        outData_ = (uint8_t *)av_malloc(out_size_);
    }
    memset(outData_, 0, out_size_);
    
    const uint8_t **in = (const uint8_t **)inFrame->data;
    out_nb_samples_ = swr_convert(swr_context_, &outData_, out_count, in, inFrame->nb_samples);
    *dataSize = out_size_;
    if (out_nb_samples_ < 0) {
        return nullptr;
    }
    
    return outData_;
}

bool CSJAudioConverter::initConverter(int in_nb_sample,
                                      int out_nb_sample,
                                      int in_sample_rate,
                                      int out_sample_rate,
                                      AVChannelLayout *in_channel_layout,
                                      AVChannelLayout *out_channel_layout,
                                      AVSampleFormat in_sample_fmt,
                                      AVSampleFormat out_sample_fmt) {
    int ret = swr_alloc_set_opts2(&swr_context_,
                                  out_channel_layout,
                                  out_sample_fmt,
                                  out_sample_rate,
                                  in_channel_layout,
                                  in_sample_fmt,
                                  in_sample_rate,
                                  0,
                                  NULL);
    if (ret < 0) {
        return false;
    }
    
    ret = swr_init(swr_context_);
    if (ret < 0) {
        return false;
    }
    
    return true;
}
