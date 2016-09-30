# XXPhotoPicker
XXPhotoPicker 最终希望能达到的性能标准是系统的照片应用
iOS 8 提供的Photos.framework 让我们可以更加容易的获得 Image,Video,Audio,LivePhoto资源，你可以获得基本上所有的信息来使你的App在交互和内容上更加自由和丰富。你可以非常自由的创建自己的相册，你可以编辑图片，你可以同步iCloud上的照片，总之基本上你可以创造出一个跟照片一模一样的应用。

我们比较关注的是图片瀑布流快速滑动时产生的性能和内存问题，同样在预览模式下如何快速、高效的载入高质量的图片。如果你的照片资源非常大的时候，这是个比较麻烦的问题需要解决，如何在体验和性能上做出平衡，这个值得深思。
## 运行环境
- iOS 8+
- Photos.framework
- 支持 armv7/armv7s/arm64
## 示例
```objc
PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
options.resizeMode = PHImageRequestOptionsResizeModeExact;
CGFloat maxPixel = MAX(asset.pixelWidth, asset.pixelHeight);
maxPixel = MIN(maxPixel, xxAssetImageMaxPixel);
CGSize size = CGSizeMake(maxPixel, maxPixel);
PHImageRequestID ID =
[self.imageManager requestImageForAsset:asset
                             targetSize:size  //并不是总是返回指定尺寸的图片，你需要设置resizeMode为PHImageRequestOptionsResizeModeExact
                            contentMode:PHImageContentModeAspectFit   //PHImageContentModeAspectFill 发现在ios8上有比较严重的性能问题，建议使用PHImageContentModeAspectFit
                                options:options
                          resultHandler:^(UIImage *result, NSDictionary *info) {
    }];
```
通常情况下request是一个异步请求，但是在高速缓存的模式下并不是这样，低质量和高质量的图片也有可能是在同步的状态下直接在主线程下获得图片的实例，这大大加快了图片的读取速度。然而即使request是在异步情况下读取图片，request的性能消耗依然严重，尤其图片像素在6000*6000以上的时候能明显感觉的卡顿。
如何灵活的使用`PHCachingImageManager`做高速缓存是个需要不断思考的问题。

## 依赖
本项目使用Masonry 写界面布局，运行前请在项目根目录执行`pod install` 命令
