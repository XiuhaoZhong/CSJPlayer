//
//  CSJCommomTools.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/23.
//

#import "CSJCommomTools.h"

@implementation CSJCommomTools

@end

@implementation CSJTimeTools

+ (NSString *)time_HHMMSSFromSecs:(NSInteger)secs {
    if (secs == 0) {
        return @"00:00:00";
    }
    
    NSInteger hours = 0;
    NSInteger mins = 0;
    NSInteger seconds = 0;
    
    seconds = secs % 60;
    mins = secs / 60;
    hours = mins / 60;
    mins %= 60;
    
    NSString *minStr = @"";
    if (mins == 0) {
        minStr = @"00";
    } else if (mins >= 10) {
        minStr = [NSString stringWithFormat:@"%@", @(mins)];
    } else {
        minStr = [NSString stringWithFormat:@"0%@", @(mins)];
    }
    
    NSString *secStr = @"";
    if (seconds == 0) {
        secStr = @"00";
    } else if (seconds >= 10) {
        secStr = [NSString stringWithFormat:@"%@", @(seconds)];
    } else {
        secStr = [NSString stringWithFormat:@"0%@", @(seconds)];
    }
    
    NSString *hourStr = @"";
    if (hours == 0) {
        hourStr = @"00";
    } else if (hours >= 10) {
        hourStr = [NSString stringWithFormat:@"%@", @(hours)];
    } else {
        hourStr = [NSString stringWithFormat:@"0%@", @(hours)];
    }
    
    NSString *timeStr = [NSString stringWithFormat:@"%@:%@:%@", hourStr, minStr, secStr];
    
    return timeStr;
}

@end
