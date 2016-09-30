//
//  ViewController.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "ViewController.h"
#import "XXAssetGridViewController.h"
#import "XXPhotoAlbumViewController.h"
#import "XXPhotoPicker.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[XXPhotoPicker shareInstance] showPicker:^(NSArray *thumbnails, NSArray *largePics, BOOL isCanceled) {
            NSLog(@"123");
        }];
    });

}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];


}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
