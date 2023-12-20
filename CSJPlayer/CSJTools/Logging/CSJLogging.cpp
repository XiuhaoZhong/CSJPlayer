//
//  CSJLogging.cpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/8.
//

#include "CSJLogging.hpp"
#include <mutex>

CSJLoggingPtr CSJLogging::instance_;
static std::once_flag loggingOnceFlag;

CSJLogging::CSJLogging() {
    
}

CSJLogging::~CSJLogging() {
    
}

CSJLoggingPtr CSJLogging::getInstance() {
    std::call_once(loggingOnceFlag, [&] {
        instance_ = std::make_shared<CSJLogging>();
    });
    
    return instance_;
}
