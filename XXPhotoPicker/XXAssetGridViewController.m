//
//  XXAssetGridViewController.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXAssetGridViewController.h"
#import "Masonry.h"
#import "XXGridViewCell.h"
#import "UICollectionView+Convenience.h"
#import "XXAssetViewController.h"
#import "XXPhotoPicker.h"

#define UIColorFromRGB(rgbValue)	[UIColor colorWithRed:((float)(((rgbValue) & 0xFF0000) >> 16))/255.0 \
green:((float)(((rgbValue) & 0x00FF00) >> 8))/255.0 \
blue:((float)((rgbValue) & 0x0000FF))/255.0 \
alpha:1.0]

@interface XXAssetGridStatusBar : UIView
@property (nonatomic, strong) UILabel *numberLabel;
@end
@implementation XXAssetGridStatusBar
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self setupViews];
    }
    return self;
}
- (void)setupViews{
    
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = UIColorFromRGB(0xdfdfdf);
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.width.equalTo(self);
        make.height.mas_equalTo(0.5);
    }];

    UIButton *sendBtn = [[UIButton alloc] init];
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn setTitleColor:UIColorFromRGB(0xffad2c) forState:UIControlStateNormal];
    sendBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [sendBtn addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:sendBtn];
    [sendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.right.equalTo(self);
        make.width.mas_equalTo(60);
        make.height.equalTo(self);
    }];
    
    UILabel *numberLabel = [[UILabel alloc] init];
    [numberLabel setTextColor:[UIColor whiteColor]];
    numberLabel.font = [UIFont systemFontOfSize:16];
    numberLabel.layer.cornerRadius = 11;
    numberLabel.clipsToBounds = YES;
    numberLabel.textAlignment = NSTextAlignmentCenter;
    numberLabel.backgroundColor = UIColorFromRGB(0x09bb07);
    [self addSubview:numberLabel];
    [numberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(sendBtn.mas_left).offset(5);
        make.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
    _numberLabel = numberLabel;
    [self updateNumbers:0];
}
- (void)updateNumbers:(NSInteger)number{
    if (number > 0) {
        _numberLabel.hidden = NO;
        _numberLabel.text = @(number).description;
    }
    else{
        _numberLabel.hidden = YES;
    }
}
- (void)send:(id)sender{
    [[XXPhotoPicker shareInstance] send];
}
@end

@interface XXAssetGridViewController () <UICollectionViewDataSource, UICollectionViewDelegate, PHPhotoLibraryChangeObserver, XXGridViewCellDelegate, XXPhotoPickerDataObserve>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) XXAssetGridStatusBar *statusBar;

@property (nonatomic, assign) NSInteger firstLoad;
@property CGRect previousPreheatRect;
@end

@implementation XXAssetGridViewController

static NSString *const GridViewCellIdentifier = @"GridViewCellIdentifier";
static CGSize AssetGridThumbnailSize;
- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}
- (id)init{
    self = [super init];
    if (self) {
        if (!_assetsFetchResults) {
            self.title = @"相册";
            [self fetchAssets];
        }
        self.imageManager = [[PHCachingImageManager alloc] init];
        
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        [self resetCachedAssets];
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    
    [self updateCachedAssets];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [[XXPhotoPicker shareInstance] addPhotoChangeListener:self];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self resetCachedAssets];
    [[XXPhotoPicker shareInstance] removePhotoChangeListener:self];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if (_firstLoad <=1 && self.assetsFetchResults.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.assetsFetchResults.count-1 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
    _firstLoad ++;
 
}
- (void)fetchAssets{
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *allPhotos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosOptions];
    self.assetsFetchResults = allPhotos;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    [self.navigationItem setRightBarButtonItem:barButtonItem];
    
    self.view.backgroundColor = [UIColor whiteColor];
    NSInteger photosOneLine = 4;
    CGFloat margin = 4;
    CGFloat item = (self.view.bounds.size.width - (photosOneLine +1)*margin)/photosOneLine;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    layout.itemSize     = CGSizeMake(item, item);
    layout.sectionInset = UIEdgeInsetsMake(margin, margin, 0, margin);
    
    UICollectionView *collectionView    = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.contentInset = UIEdgeInsetsMake(0, 0, 45, 0);
    [self.view addSubview:collectionView];
    
    [collectionView registerClass:[XXGridViewCell class] forCellWithReuseIdentifier:GridViewCellIdentifier];
    
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make){
        make.edges.equalTo(self.view);
    }];
    
    self.collectionView = collectionView;
    self.collectionViewLayout = layout;
    
    XXAssetGridStatusBar *statusBar = [[XXAssetGridStatusBar alloc] init];
    [self.view addSubview:statusBar];
    [statusBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.mas_equalTo(45);

    }];
    _statusBar = statusBar;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)cancel:(id)sender{
    [[XXPhotoPicker shareInstance] cancel];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (PHAsset *)findAssetByIdentifier:(NSString *)identifier{
    __block PHAsset *asset = nil;
    [_assetsFetchResults enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[(PHAsset *)obj localIdentifier] isEqual:identifier]) {
            *stop = YES;
            asset = obj;
        }
    }];
    return asset;
}
#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    XXGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GridViewCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.photoSelected = [[XXPhotoPicker shareInstance] photoSelected:asset];
    cell.imageManager = _imageManager;

    cell.asset = asset;
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    XXAssetViewController *ctr = [[XXAssetViewController alloc] init];
    ctr.assetsFetchResults = _assetsFetchResults;
    ctr.visiableAssetIndex = indexPath.item;
    [self.navigationController pushViewController:ctr animated:YES];
}
#pragma mark - XXGridViewCellDelegate
- (void)photoThumbnailSelected:(BOOL)selected identifier:(NSString *)identifier{
    PHAsset *asset = [self findAssetByIdentifier:identifier];
    if (!selected) {
        [[XXPhotoPicker shareInstance] deselectPhoto:asset];
    }else{
        [[XXPhotoPicker shareInstance] selectPhoto:asset];
    }
}
#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchAssets];
        [self.collectionView reloadData];
    });
}

#pragma mark - XXPhotoPickerDataObserve
- (void)updatePhotosCount:(NSNumber *)count{
    [_statusBar updateNumbers:[count integerValue]];
    if (self.isViewLoaded && self.view.window) {
        return;
    }
    [_collectionView reloadData];
}
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Update cached assets for the new visible area.
    [self updateCachedAssets];
}
#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil && _firstLoad >=2;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, - 0.5f*CGRectGetHeight(preheatRect));
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds)/3) {
        
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView xx_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView xx_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFit
                                               options:options];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFit
                                              options:options];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    
    return assets;
}

@end
