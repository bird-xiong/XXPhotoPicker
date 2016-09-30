//
//  XXPhotoPicker.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXPhotoPicker.h"
#import "XXAssetGridViewController.h"
#import "XXPhotoAlbumViewController.h"

@interface XXPhotoPicker ()
@property (nonatomic, strong) NSMutableArray *selectedArray;
@property (nonatomic, strong) NSMutableArray *listeners;
@property (nonatomic, strong) UINavigationController * navi;
@property (nonatomic, copy) XXPhotoPickerResultHandler result;
@end

@implementation XXPhotoPicker
+(XXPhotoPicker *)shareInstance{
    static XXPhotoPicker *sharedPhotoPicker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPhotoPicker = [[XXPhotoPicker alloc] init];
    });
    return sharedPhotoPicker;
}
- (id)init{
    self = [super init];
    if (self) {
        _selectedArray = [NSMutableArray array];
        _listeners = [NSMutableArray array];
    }
    return self;
}
- (void)clearData{
    [_selectedArray removeAllObjects];
    [_listeners removeAllObjects];
    self.navi   = nil;
    self.result = nil;
}
- (void)showPicker:(XXPhotoPickerResultHandler)handler{
    self.result = handler;
    
    XXPhotoAlbumViewController *album = [[XXPhotoAlbumViewController alloc] init];
    XXAssetGridViewController  *grid  = [[XXAssetGridViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] init];
    [nav setViewControllers:@[album,grid]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nav animated:YES completion:nil];
    _navi = nav;
}


#pragma mark - XXPhotoPickerDelegate And XXPhotoPickerDataSource Methods
- (void)cancel{
    __weak __block typeof(self) WeakSelf = self;
    [_navi dismissViewControllerAnimated:YES completion:^{
        WeakSelf.result(nil,nil,YES);
        [WeakSelf clearData];
    }];
}
- (void)send{
    if (_selectedArray.count > 0) {
        [self requsetPhotos:_selectedArray completion:^(UIImage *thumbail, UIImage *largePic, PHAsset *asset, BOOL isEnd) {
            if (isEnd) {
                __weak __block typeof(self) WeakSelf = self;
                [_navi dismissViewControllerAnimated:YES completion:^{
                    WeakSelf.result(nil,nil,NO);
                    [WeakSelf clearData];
                }];
            }
        }];
    }
    else{
        [self cancel];
    }
}
- (void)selectPhoto:(PHAsset *)asset{
    [_selectedArray addObject:asset];
    [_listeners makeObjectsPerformSelector:@selector(updatePhotosCount:) withObject:@(_selectedArray.count)];
}
- (void)deselectPhoto:(PHAsset *)asset{
    if ([_selectedArray containsObject:asset]) {
        [_selectedArray removeObject:asset];
    }
    [_listeners makeObjectsPerformSelector:@selector(updatePhotosCount:) withObject:@(_selectedArray.count)];
}
- (BOOL)photoSelected:(PHAsset *)asset{
    return [_selectedArray containsObject:asset];
}
- (void)addPhotoChangeListener:(id<XXPhotoPickerDataObserve>)object{
    [_listeners addObject:object];
    [object updatePhotosCount:@(_selectedArray.count)];
}
- (void)removePhotoChangeListener:(id<XXPhotoPickerDataObserve>)object{
    if ([_listeners containsObject:object]) {
        [_listeners removeObject:object];
    }
}

#pragma mark - Photo Requset Methods
- (BOOL)nextPhoto:(PHAsset *)asset{
    if (_selectedArray.count > 0 && [_selectedArray indexOfObject:asset] != _selectedArray.count -1) {
        return YES;
    }
    return NO;
}
- (PHAsset *)nextToAsset:(PHAsset *)asset{
    if ([_selectedArray indexOfObject:asset] != _selectedArray.count -1) {
        return _selectedArray[[_selectedArray indexOfObject:asset]+1];
    }
    return nil;
}
- (void)requsetPhotos:(id)assets completion:(void(^)(UIImage *thumbail,UIImage *largePic,PHAsset *asset,BOOL isEnd))completion{
    PHAsset *asset = assets;
    if ([assets isKindOfClass:[NSArray class]]) {
        asset = assets[0];
    }
    [self requestLargePicImageAsset:asset completion:^(UIImage *thumbail) {
        [self requestThumbnailImageAsset:asset completion:^(UIImage *largePic) {
            completion(thumbail,largePic,asset,![self nextPhoto:asset]);
            if ([self nextPhoto:asset]) {
                [self requsetPhotos:[self nextToAsset:asset] completion:completion];
            }
        }];
    }];
}
- (void)requestThumbnailImageAsset:(PHAsset *)asset completion:(void(^)(UIImage *result))completion{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    CGSize  size    = CGSizeMake(154, 154);
    if (asset.pixelWidth < size.width && asset.pixelHeight < size.height) {
        size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    }
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:size
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                completion(result);
                                            }];
}
- (void)requestLargePicImageAsset:(PHAsset *)asset completion:(void(^)(UIImage *result))completion{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    CGSize  size    = [UIScreen mainScreen].bounds.size;
    if (asset.pixelWidth < size.width && asset.pixelHeight < size.height) {
        size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    }
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:size
                                              contentMode:PHImageContentModeAspectFit
                                                  options:options
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                completion(result);
                                            }];
}
@end