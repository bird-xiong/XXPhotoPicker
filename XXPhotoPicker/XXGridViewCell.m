//
//  XXGridViewCell.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXGridViewCell.h"
#import "Masonry.h"
#import "XXPhotoPicker.h"

#define kSelectButtonSize CGSizeMake(22, 22)

@interface XXGridViewCell ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *selectButton;
@property (nonatomic, assign) PHImageRequestID requestID;
@end
@implementation XXGridViewCell
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:frame];
        _imageView.contentMode  = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds= YES;
        [self addSubview:_imageView];
        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectButton setImage:[UIImage imageNamed:@"feedback_btn_ok"] forState:UIControlStateNormal];
        [_selectButton setImage:[UIImage imageNamed:@"feedback_btn_okin"] forState:UIControlStateSelected];
        [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
        _selectButton.adjustsImageWhenHighlighted = NO;
        [self addSubview:_selectButton];
        [_selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.right.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(kSelectButtonSize.width+4,kSelectButtonSize.height+4));
        }];
    }
    return self;
}
- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self cancelPreviousRequest];
    
    self.requestID = PHInvalidImageRequestID;
    self.imageView.image = nil;
    self.asset = nil;
    self.photoSelected = NO;
}
- (void)setAsset:(PHAsset *)asset{
    if (asset != _asset) {
        
        [self cancelPreviousRequest];
        
        _asset = asset;
        
        if (asset) {
            CGFloat cropSideLength
            = MIN(asset.pixelWidth, asset.pixelHeight);
            cropSideLength
            = MIN(cropSideLength, _imageView.bounds.size.width*[UIScreen mainScreen].scale);
            CGSize retinaSquare = CGSizeMake(cropSideLength, cropSideLength);
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            __block BOOL isHighQualityAynchronous = NO;
            __block BOOL aynchronousHelper = NO;
            __weak typeof(self) WeakSelf = self;
            PHImageRequestID ID =
            [self.imageManager requestImageForAsset:asset
                                         targetSize:retinaSquare
                                        contentMode:PHImageContentModeAspectFit
                                            options:options
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          //degraded image must be synchronous
                                          BOOL degraded = [info[PHImageResultIsDegradedKey] boolValue];
                                          //degraded image
                                          if (degraded) {
                                              WeakSelf.imageView.image = result;
                                          }
                                          //highQuality image
                                          else if(!degraded &&
                                                  (([info[PHImageResultRequestIDKey] integerValue] == WeakSelf.requestID
                                                    && WeakSelf.requestID != PHInvalidImageRequestID)
                                                   || !aynchronousHelper)){
                                                      WeakSelf.imageView.image = result;
                                                      WeakSelf.requestID = PHInvalidImageRequestID;
                                                  }
                                          if (!aynchronousHelper && !degraded) {
                                              isHighQualityAynchronous = YES;
                                          }
                                      }];
            aynchronousHelper = YES;
            if (!isHighQualityAynchronous) {
                _requestID = ID;
            }
        }
    }
}
//iOS 9.0 aviable
- (void)highApiSetAsset:(PHAsset *)asset{
    CGFloat cropSideLength
    = MIN(asset.pixelWidth, asset.pixelHeight);
    cropSideLength
    = MIN(cropSideLength, _imageView.bounds.size.width*[UIScreen mainScreen].scale);
    CGSize retinaSquare = CGSizeMake(cropSideLength, cropSideLength);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    __block BOOL isHighQualityAynchronous = NO;
    __weak typeof(self) WeakSelf = self;
    PHImageRequestID ID =
    [self.imageManager requestImageForAsset:asset
                                 targetSize:retinaSquare
                                contentMode:PHImageContentModeAspectFit
                                    options:options
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  //degraded image must be synchronous
                                  BOOL degraded = [info[PHImageResultIsDegradedKey] boolValue];
                                  BOOL fromeCache= [info[@"PHImageResultIsFromCacheKey"] boolValue];
                                  NSLog(@"fromeCache %d",fromeCache);
                                  //degraded image
                                  if (degraded) {
                                      WeakSelf.imageView.image = result;
                                  }
                                  //highQuality image
                                  else if(!degraded
                                          && (([info[PHImageResultRequestIDKey] integerValue] == WeakSelf.requestID
                                               && WeakSelf.requestID != PHInvalidImageRequestID)
                                              || fromeCache)){
                                              WeakSelf.imageView.image = result;
                                              WeakSelf.requestID = PHInvalidImageRequestID;
                                          }
                                  if (fromeCache && !degraded) {
                                      isHighQualityAynchronous = YES;
                                  }
                              }];
    if (!isHighQualityAynchronous) {
        _requestID = ID;
    }
}
- (void)setPhotoSelected:(BOOL)photoSelected{
    _selectButton.selected = photoSelected;
}
- (void)select:(id)sender{
    UIButton *btn = (UIButton *)sender;
    btn.selected = !btn.selected;
    if (_delegate) {
        [_delegate photoThumbnailSelected:btn.selected identifier:_asset.localIdentifier];
    }
}
- (void)cancelPreviousRequest{
    if (_requestID != PHInvalidImageRequestID) {
        [self.imageManager cancelImageRequest:_requestID];
        _requestID = PHInvalidImageRequestID;
    }
}
@end
