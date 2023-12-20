//
//  CSJAVFoundDecoder.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/6/19.
//

#import "CSJAVFoundDecoder.h"

#import <AVFoundation/AVFoundation.h>

@interface CSJAVFoundDecoder()

@property (nonatomic, strong) AVAsset *mediaAsset;

@end

@implementation CSJAVFoundDecoder

- (instancetype)initWithUrl:(NSString *)mediaURL {
    if (self = [super init]) {
        //_mediaAsset = [AVAsset assetWithURL:[NSURL URLWithString:mediaURL]];
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"nightAskDay" withExtension:@"mp4"];
        _mediaAsset = [AVAsset assetWithURL:url];
    }
    
    return self;
}

- (void)outputTrackInfos {
    NSArray<AVAssetTrack *> *tracks = _mediaAsset.tracks;
    if (tracks.count == 0) {
        NSLog(@"current media doesn't have any tracks!");
        return ;
    }
    
    CMTime time = [_mediaAsset duration];
    int seconds = ceil(time.value / time.timescale);
    NSLog(@"media duration: %@s", @(seconds));
    
    for (AVAssetTrack *track in tracks) {
        NSLog(@"trackID: %@", @(track.trackID));
        NSLog(@"mediaType: %@", track.mediaType);
        
        NSArray *descritiops = track.formatDescriptions;
        if (descritiops.count > 0) {
            NSLog(@"there are some format descriptions!");
            CMFormatDescriptionRef descRef = (__bridge CMFormatDescriptionRef)descritiops[0];
        }
    }
    
}

@end
