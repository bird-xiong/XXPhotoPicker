//
//  XXPhotoPicker.h
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Photos;

@protocol XXPhotoPickerDataObserve <NSObject>
- (void)updatePhotosCount:(NSNumber *)count;
@end

@protocol XXPhotoPickerDelegate <NSObject>
- (void)cancel;
- (void)send;
- (void)selectPhoto:(PHAsset *)asset;
- (void)deselectPhoto:(PHAsset *)asset;
@end

@protocol XXPhotoPickerDataSource <NSObject>
- (BOOL)photoSelected:(PHAsset *)asset;
@end

typedef void(^XXPhotoPickerResultHandler)(NSArray *thumbnails, NSArray *largePics, BOOL isCanceled);
@interface XXPhotoPicker : NSObject <XXPhotoPickerDelegate, XXPhotoPickerDataSource>
+ (XXPhotoPicker *)shareInstance;
- (void)showPicker:(XXPhotoPickerResultHandler)handler;

- (void)addPhotoChangeListener:(id<XXPhotoPickerDataObserve>)object;
- (void)removePhotoChangeListener:(id<XXPhotoPickerDataObserve>)object;
@end