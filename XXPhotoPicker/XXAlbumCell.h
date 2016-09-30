//
//  XXAlbumCell.h
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXAlbumCell : UITableViewCell
@property (nonatomic, copy)   NSString *representedAssetIdentifier;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger count;
@end