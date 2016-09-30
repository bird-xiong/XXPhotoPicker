//
//  XXAssetViewCell.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/22.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXAssetViewCell.h"
#import "Masonry.h"

@interface XXAssetViewCell () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) PHImageRequestID requestID;
@end

@implementation XXAssetViewCell
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        UIScrollView *scrollView    = [[UIScrollView alloc] init];
        scrollView.backgroundColor  = [UIColor blackColor];
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        scrollView.delegate = self;
        [self addSubview:scrollView];
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        _scrollView = scrollView;
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.clipsToBounds= YES;
        imageView.backgroundColor = [UIColor blackColor];
        imageView.contentMode  = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:imageView];
        //        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        //            make.edges.equalTo(self);
        //        }];
        _imageView = imageView;
        
        // 监听点击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.delaysTouchesBegan = YES;
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        
        [singleTap requireGestureRecognizerToFail:doubleTap];
        
    }
    return self;
}

#pragma mark 调整frame
- (void)adjustFrame
{
    if (_imageView.image == nil) return;
    
    // 基本尺寸参数
    CGFloat boundsWidth = self.bounds.size.width;
    CGFloat boundsHeight = self.bounds.size.height;
    CGFloat imageWidth = _imageView.image.size.width;
    CGFloat imageHeight = _imageView.image.size.height;
    
    CGFloat widthScale  = boundsWidth/imageWidth;
    CGFloat heightScale = boundsHeight/imageHeight;
    
    //    if (widthScale >= 1 && heightScale >= 1 && self.requestID =) {
    //        self.scrollView.maximumZoomScale = 1;
    //        self.scrollView.minimumZoomScale = 1;
    //        self.scrollView.zoomScale = 1;
    //
    //        CGRect imageFrame = CGRectMake((boundsWidth - imageWidth)*0.5, (boundsHeight - imageHeight)*0.5, imageWidth, imageHeight);
    //        self.scrollView.contentSize = CGSizeMake(boundsWidth, boundsHeight);
    //        _imageView.frame = imageFrame;
    //    }
    //    else
    {
        
        CGFloat scale = MIN(widthScale, heightScale);
        self.scrollView.maximumZoomScale = 1/scale;
        self.scrollView.minimumZoomScale = 1;
        self.scrollView.zoomScale = 1;
        
        imageWidth  = imageWidth*scale;
        imageHeight = imageHeight*scale;
        
        CGRect imageFrame = CGRectMake((boundsWidth - imageWidth)*0.5, (boundsHeight - imageHeight)*0.5, imageWidth, imageHeight);
        self.scrollView.contentSize = CGSizeMake(boundsWidth, boundsHeight);
        _imageView.frame = imageFrame;
    }
}
- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self cancelPreviousRequest];
    self.requestID = PHInvalidImageRequestID;
    self.imageView.image = nil;
    self.asset = nil;
    self.preheatImage = nil;
}
const static CGFloat xxAssetImageMaxPixel = 3660;
- (void)setAsset:(PHAsset *)asset{
    if (asset != _asset) {
        
        [self adjustFrame];
        [self cancelPreviousRequest];
        
        _asset = asset;
        
        if (asset) {
            __weak typeof(self) WeakSelf = self;
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            options.resizeMode = PHImageRequestOptionsResizeModeExact;
            CGFloat maxPixel = MAX(asset.pixelWidth, asset.pixelHeight);
            maxPixel = MIN(maxPixel, xxAssetImageMaxPixel);
            CGSize size = CGSizeMake(maxPixel, maxPixel);
            __block BOOL isHighQualityAynchronous = NO;
            __block BOOL aynchronousHelper = NO;
            PHImageRequestID ID =
            [self.imageManager requestImageForAsset:asset
                                         targetSize:size
                                        contentMode:PHImageContentModeAspectFit
                                            options:options
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          //degraded image must be synchronous
                                          BOOL degraded = [info[PHImageResultIsDegradedKey] boolValue];
                                          //degraded image
                                          if (degraded) {
                                              WeakSelf.imageView.image = result;
                                              [WeakSelf adjustFrame];
                                          }
                                          //highQuality image
                                          else if(!degraded &&
                                                  (([info[PHImageResultRequestIDKey] integerValue] == WeakSelf.requestID
                                                    && WeakSelf.requestID != PHInvalidImageRequestID)
                                                   || !aynchronousHelper)){
                                                      //                                              NSLog(@"%@",NSStringFromCGSize(result.size));
                                                      WeakSelf.imageView.image = result;
                                                      WeakSelf.requestID = PHInvalidImageRequestID;
                                                      [WeakSelf adjustFrame];
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
- (void)setPreheatImage:(UIImage *)preheatImage{
    if (_preheatImage != preheatImage) {
        _preheatImage = preheatImage;
        self.imageView.image = preheatImage;
    }
}
- (void)cancelPreviousRequest{
    if (_requestID != PHInvalidImageRequestID) {
        [self.imageManager cancelImageRequest:_requestID];
        _requestID = PHInvalidImageRequestID;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    CGSize boundsSize = self.bounds.size;
    
    CGRect frameToCenter = self.imageView.frame;
    
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    self.imageView.frame = frameToCenter;
}
#pragma mark - 手势处理
//单击隐藏
- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    if (_delegate && [_delegate respondsToSelector:@selector(assetViewTaped)]) {
        [_delegate assetViewTaped];
    }
}
//双击放大
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        CGPoint touchPoint  = [tap locationInView:_imageView];
        CGRect rectTozoom=[self zoomRectForScale:self.scrollView.maximumZoomScale withCenter:touchPoint];
        [self.scrollView zoomToRect:rectTozoom animated:YES];
    } else {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [self frame].size.height / scale;
    zoomRect.size.width  = [self frame].size.width  / scale;
    
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}
@end