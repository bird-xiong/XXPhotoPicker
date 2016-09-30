//
//  XXGridViewCell.h
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;

@protocol XXGridViewCellDelegate;

@interface XXGridViewCell : UICollectionViewCell
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) BOOL photoSelected;
@property (nonatomic, weak) id<XXGridViewCellDelegate> delegate;
@end

@protocol XXGridViewCellDelegate <NSObject>
@required
- (void)photoThumbnailSelected:(BOOL)selected identifier:(NSString *)identifier;
@end