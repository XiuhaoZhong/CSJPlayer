//
//  CSJLogging.hpp
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/8.
//

#ifndef CSJLogging_hpp
#define CSJLogging_hpp

#include <stdio.h>
#include <memory>

class CSJLogging {
public:
    CSJLogging();
    ~CSJLogging();
    
    static std::shared_ptr<CSJLogging> getInstance();
    
private:
    static std::shared_ptr<CSJLogging> instance_;
};

using CSJLoggingPtr = std::shared_ptr<CSJLogging>;

#endif /* CSJLogging_hpp */
