//
//  XXAssetViewController.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/22.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXAssetViewController.h"
#import "XXAssetViewCell.h"
#import "Masonry.h"
#import "XXPhotoPicker.h"

#define UIColorFromRGB(rgbValue)	[UIColor colorWithRed:((float)(((rgbValue) & 0xFF0000) >> 16))/255.0 \
green:((float)(((rgbValue) & 0x00FF00) >> 8))/255.0 \
blue:((float)((rgbValue) & 0x0000FF))/255.0 \
alpha:1.0]

@interface XXAssetViewController() <UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, XXPhotoPickerDataObserve, XXAssetViewCellDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, assign) NSInteger firstLoad;

@property (nonatomic, strong) UIView *customBar;
@property (nonatomic, strong) UIView *customTool;
@property (nonatomic, strong) NSMutableArray *reusableCells;
@property (nonatomic, strong) NSMutableArray *reusableImages; //only for first load
@end
@implementation XXAssetViewController
static NSString *const ReusableLeftCellIdentifier   = @"ReusableLeftCellIdentifier";
static NSString *const ReusableMidIdentifier        = @"ReusableMidIdentifier";
static NSString *const ReusableRightIdentifier      = @"ReusableRightIdentifier";
- (id)init{
    self = [super init];
    if (self) {
        self.title = @"";
        self.imageManager   = [[PHCachingImageManager alloc] init];
        self.reusableCells  = [NSMutableArray array];
        self.reusableImages = [NSMutableArray array];
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.customBar = [self customNavigationBar];
    [self.view addSubview:_customBar];
    [_customBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.mas_equalTo(64);
    }];
    
    self.customTool = [self customToolBar];
    [self.view addSubview:_customTool];
    [_customTool mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.mas_equalTo(45);
    }];
    
    if (_assetsFetchResults.count > _visiableAssetIndex) {
        PHAsset *asset  = self.assetsFetchResults[_visiableAssetIndex];
        self.title
        = asset.burstIdentifier;
    }
    self.automaticallyAdjustsScrollViewInsets = NO;  
    self.view.backgroundColor = [UIColor whiteColor];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 10;
    
    UICollectionView *collectionView    = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = YES;
    collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 10);
    [self.view addSubview:collectionView];
    
    [collectionView registerClass:[XXAssetViewCell class] forCellWithReuseIdentifier:ReusableLeftCellIdentifier];
    [collectionView registerClass:[XXAssetViewCell class] forCellWithReuseIdentifier:ReusableMidIdentifier];
    [collectionView registerClass:[XXAssetViewCell class] forCellWithReuseIdentifier:ReusableRightIdentifier];
    
    [collectionView mas_makeConstraints:^(MASConstraintMaker *make){
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view).offset(10);
        make.height.equalTo(self.view);
    }];
    
    self.collectionView = collectionView;
    self.collectionViewLayout = layout;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(back:)];
    [self.navigationController.navigationItem setLeftBarButtonItem:item];
    
    [self.view bringSubviewToFront:_customBar];
    [self.view bringSubviewToFront:_customTool];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[XXPhotoPicker shareInstance] addPhotoChangeListener:self];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[XXPhotoPicker shareInstance] removePhotoChangeListener:self];
}
- (void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if (_firstLoad <=1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_visiableAssetIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
    _firstLoad ++;
    
}
- (void)getNearByPrepareReuseAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *identifiers = @[ReusableLeftCellIdentifier,ReusableMidIdentifier,ReusableRightIdentifier];
    NSInteger tag = indexPath.item%3;
    
    NSString *identifier = identifiers[tag];
    NSString *left  = ReusableLeftCellIdentifier;
    NSString *right = ReusableRightIdentifier;
    if ([identifier isEqual:ReusableLeftCellIdentifier]) {
        left = ReusableRightIdentifier;
        right= ReusableMidIdentifier;
    }
    if ([identifier isEqual:ReusableRightIdentifier]) {
        left = ReusableMidIdentifier;
        right= ReusableLeftCellIdentifier;
    }
    
    XXAssetViewCell *leftCell   = [self findReuseCellAtForIdentifier:left];
    XXAssetViewCell *rightCell  = [self findReuseCellAtForIdentifier:right];

    if (indexPath.item > 0) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item-1];
        if (leftCell != nil) {
            leftCell.asset = asset;
        }
        else{
            [self loadUnReuseCellAssetImage:asset];
        }
    }
    
    if (indexPath.item < self.assetsFetchResults.count-1) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item+1];
        if (rightCell != nil) {
            rightCell.asset = asset;
        }
        else{
            [self loadUnReuseCellAssetImage:asset];
        }
    }
}
//first reuse is for middle and right cell
- (void)loadUnReuseCellAssetImage:(PHAsset *)asset{
    __weak __block typeof(self) WeakSelf = self;
    CGFloat scale   = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [self.imageManager requestImageForAsset:asset
                                 targetSize:CGSizeMake(cellSize.width*scale,cellSize.height*scale)
                                contentMode:PHImageContentModeAspectFit
                                    options:options
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if (result) {
                                      [WeakSelf assetReuse:asset image:result];
                                  }
                              }];
}
//insert image
- (void)assetReuse:(PHAsset *)asset image:(UIImage *)image{
    __block NSDictionary *result = nil;
    [_reusableImages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dict = obj;
        if ([dict[@"LocalIdentifier"] isEqualToString:asset.localIdentifier]) {
            result = dict;
            *stop = YES;
        }
    }];
    if (result) {
        [_reusableImages removeObject:result];
    }
    [_reusableImages addObject:@{@"LocalIdentifier":asset.localIdentifier,@"Image":image}];
}
- (UIImage *)findPreheatImageForAsset:(PHAsset *)asset{
    __block UIImage *result = nil;
    [_reusableImages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dict = obj;
        if ([dict[@"LocalIdentifier"] isEqualToString:asset.localIdentifier]) {
            result = dict[@"Image"];
            *stop = YES;
        }
    }];
    return result;
}
- (void)removePreheatImageForAsset:(PHAsset *)asset{
     __block NSDictionary *result = nil;
    [_reusableImages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dict = obj;
        if ([dict[@"LocalIdentifier"] isEqualToString:asset.localIdentifier]) {
            result = dict;
            *stop = YES;
        }
    }];
    [_reusableImages removeObject:result];
}
- (XXAssetViewCell *)findReuseCellAtForIdentifier:(NSString *)identifier{
    __block XXAssetViewCell *cell = nil;
    [_reusableCells enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([((UICollectionViewCell *)obj).reuseIdentifier isEqualToString:identifier]) {
            cell = obj;
            *stop = YES;
        }
    }];
    return cell;
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsFetchResults.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    NSArray *identifiers = @[ReusableLeftCellIdentifier,ReusableMidIdentifier,ReusableRightIdentifier];
    XXAssetViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifiers[indexPath.item %3] forIndexPath:indexPath];
    cell.imageManager = _imageManager;
    cell.asset = asset;
    cell.delegate = self;
    
    if (![_reusableCells containsObject:cell]) {
        [_reusableCells addObject:cell];
        
        UIImage *image = [self findPreheatImageForAsset:asset];
        if (image) {
            cell.preheatImage = image;
        }
        [self removePreheatImageForAsset:asset];
    }

    [self getNearByPrepareReuseAtIndexPath:indexPath];
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    _customBar.hidden   = !_customBar.hidden;
    _customTool.hidden  = !_customTool.hidden;
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSInteger page  = (int)scrollView.contentOffset.x/(int)_collectionView.frame.size.width;
    NSInteger delx  = (int)scrollView.contentOffset.x%(int)_collectionView.frame.size.width;
    
    if (delx > _collectionView.frame.size.width *0.5f) {
        page ++;
    }
    
    if (page < self.assetsFetchResults.count) {
        PHAsset *asset = self.assetsFetchResults[page];
        UIButton *button = [_customBar viewWithTag:0x99];
        button.selected = [[XXPhotoPicker shareInstance] photoSelected:asset];
    }
}
#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.collectionView.frame.size;
}
- (BOOL)prefersStatusBarHidden{
    return YES;
}
#pragma mark - XXPhotoPickerDataObserve
- (void)updatePhotosCount:(NSNumber *)count{
    UILabel *label = [_customTool viewWithTag:0x99];
    label.hidden = [count integerValue] < 1;
    label.text = count.description;
}
#pragma mark - bar
- (void)select:(id)sender{
    UIButton *btn = (UIButton *)sender;
    btn.selected = !btn.selected;
    
    if ([_collectionView visibleCells].count >0) {
        XXAssetViewCell *cell =[[_collectionView visibleCells] firstObject];
        if (btn.selected) {
            [[XXPhotoPicker shareInstance] selectPhoto:cell.asset];
        }
        else{
            [[XXPhotoPicker shareInstance] deselectPhoto:cell.asset];
        }
    }
}
- (void)send:(id)sender{
    [[XXPhotoPicker shareInstance] send];
}
- (UIView *)customNavigationBar{
    UIView *bar         = [[UIView alloc] initWithFrame:CGRectZero];
    bar.backgroundColor = [UIColor clearColor];
    UIButton *backBtn   = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setImage:[UIImage imageNamed:@"navig_img_back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bar).offset(10);
        make.centerY.equalTo(bar).offset(10);
    }];
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColorFromRGB(0x202020);
    view.alpha = 0.75;
    [bar addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(bar);
    }];
    [bar bringSubviewToFront:backBtn];
    
    
    UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    selectButton.tag = 0x99;
    [selectButton setImage:[UIImage imageNamed:@"feedback_btn_ok"] forState:UIControlStateNormal];
    [selectButton setImage:[UIImage imageNamed:@"feedback_btn_okin"] forState:UIControlStateSelected];
    [selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    selectButton.adjustsImageWhenHighlighted = NO;
    [bar addSubview:selectButton];
    [selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(bar).offset(10);
        make.right.equalTo(bar).offset(-15);
    }];
    
    return bar;
}
- (UIView *)customToolBar{
    UIView *bar         = [[UIView alloc] initWithFrame:CGRectZero];
    bar.backgroundColor = [UIColor clearColor];
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColorFromRGB(0x202020);
    view.alpha = 0.75;
    [bar addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(bar);
    }];
    
    UIButton *sendBtn = [[UIButton alloc] init];
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    sendBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [sendBtn addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:sendBtn];
    [sendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bar);
        make.right.equalTo(bar);
        make.width.mas_equalTo(60);
        make.height.equalTo(bar);
    }];
    
    UILabel *numberLabel = [[UILabel alloc] init];
    numberLabel.tag = 0x99;
    [numberLabel setTextColor:[UIColor whiteColor]];
    numberLabel.font = [UIFont systemFontOfSize:16];
    numberLabel.layer.cornerRadius = 11;
    numberLabel.clipsToBounds = YES;
    numberLabel.textAlignment = NSTextAlignmentCenter;
    numberLabel.backgroundColor = UIColorFromRGB(0x09bb07);
    [bar addSubview:numberLabel];
    [numberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(sendBtn.mas_left).offset(5);
        make.centerY.equalTo(bar);
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
    return bar;
}
@end
