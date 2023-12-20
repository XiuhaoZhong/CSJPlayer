//
//  DevicesComboView.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/8/7.
//

#import "DevicesComboView.h"

@interface DevicesComboView ()

@property (nonatomic, strong) NSArray *deviceArray;

@end

@implementation DevicesComboView

- (instancetype)initWithDeviceArray:(NSArray *)deviceArray {
    if (self = [super init]) {
        _deviceArray = deviceArray;
        
        [self initUI];
    }
    
    return self;
}

- (void)initUI {
    
}

@end
