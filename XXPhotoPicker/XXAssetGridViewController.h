//
//  XXAssetGridViewController.h
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;

@interface XXAssetGridViewController : UIViewController
@property (nonatomic, strong) PHFetchResult *assetsFetchResults;
@property (nonatomic, strong) PHAssetCollection *assetCollection;
@end
