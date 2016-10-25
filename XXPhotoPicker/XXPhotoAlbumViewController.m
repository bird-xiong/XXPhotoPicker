//
//  XXPhotoAlbumViewController.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXPhotoAlbumViewController.h"
#import "XXAlbumCell.h"
#import "Masonry.h"
#import "XXAssetGridViewController.h"
#import "XXPhotoPicker.h"

@import Photos;
@interface XXPhotoAlbumViewController () <UITableViewDelegate, UITableViewDataSource, PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) NSArray *fetchResults;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation XXPhotoAlbumViewController
- (void)dealloc{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}
- (id)init{
    self = [super init];
    if (self) {
        self.title = @"照片";
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self fetchAssets];
    
    self.view.backgroundColor = [UIColor whiteColor];
    _tableView = [[UITableView alloc] init];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    [self.navigationItem setRightBarButtonItem:item];
}
- (void)fetchAssets{
    PHFetchResult *cameraAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    PHFetchResult *recentlyAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded options:nil];
    PHFetchResult *screenshotsAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumScreenshots options:nil];
    
    _fetchResults = @[cameraAlbum,recentlyAlbum,screenshotsAlbum];
}
- (void)cancel:(id)sender{
    [[XXPhotoPicker shareInstance] cancel];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _fetchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PHFetchResult *fetchResult = self.fetchResults[indexPath.row];
    PHAssetCollection *collection = nil;
    if (fetchResult.count>0) {
        collection = fetchResult[0];
    }
    fetchResult =
    [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    XXAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumCell"];
    if (cell == nil) {
        cell = [[XXAlbumCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AlbumCell"];
    }
    cell.name   = collection.localizedTitle;
    cell.count  = fetchResult.count;
    if (fetchResult.count > 0) {
        PHAsset *asset = [fetchResult lastObject];
        cell.representedAssetIdentifier = asset.localIdentifier;
        CGFloat scale = [UIScreen mainScreen].scale;
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(58 * scale, 58 * scale)
                                                  contentMode:PHImageContentModeAspectFill
                                                      options:nil
                                                resultHandler:^(UIImage *result, NSDictionary *info) {
                                                    // Set the cell's thumbnail image if it's still showing the same asset.
                                                    if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                                        cell.image = result;
                                                    }
                                                }];
    }
    else{
        cell.image = nil;
        cell.representedAssetIdentifier = nil;
    }
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 58;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PHFetchResult *fetchResult = self.fetchResults[indexPath.row];
    if (fetchResult.count>0) {
        PHAssetCollection *collection = fetchResult[0];
        XXAssetGridViewController *ctr = [[XXAssetGridViewController alloc] init];
        ctr.assetCollection = collection;
        ctr.title = collection.localizedTitle;
        [self.navigationController pushViewController:ctr animated:YES];
    }
}
#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchAssets];
        [self.tableView reloadData];
    });
}
@end
