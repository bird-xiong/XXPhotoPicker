//
//  XXAssetViewController.h
//  XXPhotoPicker
//
//  Created by bird on 16/9/22.
//  Copyright © 2016年 bird. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;
@interface XXAssetViewController : UIViewController
@property (nonatomic, strong) PHFetchResult *assetsFetchResults;
@property (nonatomic, assign) NSInteger visiableAssetIndex;
@end
