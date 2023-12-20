//
//  CSJFilterManager.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/9/26.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/*
    Manager filters.
    
    Keep a linkedlist for filters, you can add or remove
    one or more filters in any position that you indicate.
 
    Show all the filters could be used in a TableView
 
    You can set the filter apply mode: use only one or more
    filters at the same time.
 */

typedef NS_ENUM(NSInteger, CSJFILTERUSEMODE) {
    CSJFILTERUSEMODE_ONE = 0,   /* only use one filter. */
    CSJFILTERUSEMODE_MORE       /* use more filter in a linkedlist. */
};

@protocol CSJFilterManagerDelegate <NSObject>

- (void)selectedFilter:(NSInteger)filterType;

- (void)resetAllFilters;

@end

@interface CSJFilterManager : NSObject

@property (nonatomic, strong) NSView            *contentView;

@property (nonatomic, assign) CSJFILTERUSEMODE  filterMode;

@property (nonatomic, weak)   id<CSJFilterManagerDelegate> delegate;

- (instancetype)initWithCamera:(CSJFILTERUSEMODE)filterMode;

- (instancetype)initWithFilterMode:(CSJFILTERUSEMODE)filterMode;

@end

NS_ASSUME_NONNULL_END
