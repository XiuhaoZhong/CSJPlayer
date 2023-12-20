//
//  CSJFilterManager.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/9/26.
//

#import "CSJFilterManager.h"
#import "NSView+UIView_Custom.h"
#import "CSJFilterInfo.h"
#import "GPUImage/GPUImageView.h"

#import "Masonry.h"

@interface FilterCellItem : NSCollectionViewItem

@property (nonatomic, strong) GPUImageView *glView;
@property (nonatomic, strong) NSImageView *imgView;

@property (nonatomic, strong) NSTextField *filterNameField;

@end

@implementation FilterCellItem

- (void)viewDidLoad {
    //[self.view addSubview:self.glView];
    [self.view addSubview:self.imgView];
    [self.view addSubview:self.filterNameField];
    [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.mas_equalTo(0);
        make.height.mas_equalTo(60);
    }];
    [self.filterNameField mas_makeConstraints:^(MASConstraintMaker *make) {
        //make.top.equalTo(self.imgView.mas_bottom).offset(5);
        make.top.mas_equalTo(60);
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(15);
    }];
    
    [self.view setBackgroundColor:[NSColor grayColor]];
}

- (void)setText:(NSString *)txt {
    self.filterNameField.stringValue = txt;
}

- (void)loadView {
    self.view = [[NSView alloc] init];
}

#pragma mark - getters;
- (NSTextField *)filterNameField {
    if (!_filterNameField) {
        _filterNameField = [[NSTextField alloc] init];
        /* 没有边框，背景的透明才能有效 */
        _filterNameField.bordered = NO;
        _filterNameField.backgroundColor = [NSColor clearColor];
        _filterNameField.textColor = [NSColor blackColor];
        _filterNameField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _filterNameField.editable = NO;
        _filterNameField.layer.cornerRadius = 8;
        _filterNameField.layer.masksToBounds = YES;
        _filterNameField.alignment = NSTextAlignmentCenter;
        
    }
    
    return _filterNameField;
}

- (GPUImageView *)glView {
    if (!_glView) {
        _glView = [[GPUImageView alloc] initWithFrame:NSMakeRect(0, 0, 100, 60)];
    }
    
    return _glView;
}

- (NSImageView *)imgView {
    if (!_imgView) {
        _imgView = [[NSImageView alloc] initWithFrame:NSZeroRect];
        _imgView.image = [NSImage imageNamed:@"kitty-2948404_640.jpg"];
    }
    
    return _imgView;
}

@end

@interface CSJFilterManager() <NSTableViewDelegate, NSTableViewDataSource, NSCollectionViewDelegate, NSCollectionViewDataSource>

@property (nonatomic, strong) NSButton    *cleanFiltersBtn;

@property (nonatomic, strong) NSCollectionView *filterCollectionView;

@property (nonatomic, strong) CSJFilterInfo *filterInfo;

@end

@implementation CSJFilterManager

- (instancetype)initWithFilterMode:(CSJFILTERUSEMODE)filterMode {
    return [self initWithCamera:filterMode];
}

- (instancetype)initWithCamera:(CSJFILTERUSEMODE)filterMode {
    if (self = [super init]) {
        _filterMode = filterMode;
        
        [self initUI];
        
        [self loadAllFilters];
    }
    
    return self;
}

- (void)initUI {
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
    scrollView.hasVerticalScroller = NO;
    scrollView.hasHorizontalScroller = NO;
    
    [self.contentView addSubview:scrollView];
    //[self.contentView addSubview:self.cleanFiltersBtn];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(0);
    }];
    
    scrollView.contentView.documentView = self.filterCollectionView;
    [self.filterCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(scrollView);
        make.height.mas_equalTo(75);
    }];
    
//    [self.cleanFiltersBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.bottom.mas_equalTo(0);
//        make.height.mas_equalTo(25);
//    }];
}

- (void)loadAllFilters {
    [self.filterCollectionView reloadData];
}

- (void)cleanAllFilter {
    
}

#pragma mark - btn clicked response;
- (void)btnClicked:(NSButton *)sender {
    if (sender == self.cleanFiltersBtn) {
        [self cleanAllFilter];
    }
}

#pragma mark - overrides from NSCollectionViewDelegate & NSCollectionViewDataSource;
- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return FILTERTYPE_NUMFILTERS;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
     itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.item;
    FilterCellItem *item = (FilterCellItem *)[collectionView makeItemWithIdentifier:NSStringFromClass([FilterCellItem class]) forIndexPath:indexPath];
    
    NSString *filterName = [self.filterInfo FilterNameWithType:row];
    if (filterName.length == 0) {
        filterName = [NSString stringWithFormat:@"Unknown filter %@", @(row)];
    }
    
    [item setText:filterName];
    
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView willDisplayItem:(NSCollectionViewItem *)item forRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.item;
    FilterCellItem *itemToDisplay = (FilterCellItem *)item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSLog(@"Select an item");
}

#pragma mark - getters;
- (NSView *)contentView {
    if (!_contentView) {
        _contentView = [[NSView alloc] init];
    }
    
    return _contentView;
}

- (NSButton *)cleanFiltersBtn {
    if (!_cleanFiltersBtn) {
        _cleanFiltersBtn = [NSButton buttonWithTitle:@"清除滤镜" target:self action:@selector(btnClicked:)];
    }
    
    return _cleanFiltersBtn;
}

- (NSCollectionView *)filterCollectionView {
    if (!_filterCollectionView) {
        NSCollectionViewFlowLayout *flowLayout = [[NSCollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
        flowLayout.itemSize = CGSizeMake(100, 75);
        flowLayout.minimumLineSpacing = 2;
        
        _filterCollectionView = [[NSCollectionView alloc] initWithFrame:NSZeroRect];
        _filterCollectionView.collectionViewLayout = flowLayout;
        
        _filterCollectionView.delegate = self;
        _filterCollectionView.dataSource = self;
        _filterCollectionView.selectable = YES;
        _filterCollectionView.backgroundColors = @[[NSColor clearColor]];
        
        [_filterCollectionView registerClass:[FilterCellItem class] forItemWithIdentifier:NSStringFromClass([FilterCellItem class])];
    }
    
    return _filterCollectionView;
}

- (CSJFilterInfo *)filterInfo {
    if (!_filterInfo) {
        _filterInfo = [[CSJFilterInfo alloc] init];
    }
    
    return _filterInfo;
}

@end
