//
//  XXAssetViewCell.h
//  XXPhotoPicker
//
//  Created by bird on 16/9/22.
//  Copyright © 2016年 bird. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol XXAssetViewCellDelegate;
@import Photos;
@interface XXAssetViewCell : UICollectionViewCell
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImage *preheatImage;
@property (nonatomic, weak) id<XXAssetViewCellDelegate> delegate;
@end

@protocol XXAssetViewCellDelegate <NSObject>
- (void)assetViewTaped;
@end