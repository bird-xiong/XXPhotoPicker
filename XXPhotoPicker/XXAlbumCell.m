//
//  XXAlbumCell.m
//  XXPhotoPicker
//
//  Created by bird on 16/9/21.
//  Copyright © 2016年 bird. All rights reserved.
//

#import "XXAlbumCell.h"
#import "Masonry.h"

#define UIColorFromRGB(rgbValue)	[UIColor colorWithRed:((float)(((rgbValue) & 0xFF0000) >> 16))/255.0 \
green:((float)(((rgbValue) & 0x00FF00) >> 8))/255.0 \
blue:((float)((rgbValue) & 0x0000FF))/255.0 \
alpha:1.0]

@interface XXAlbumCell()
@property (nonatomic, strong) UIImageView *albumImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@end
@implementation XXAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.clipsToBounds= YES;
        imageView.contentMode  = UIViewContentModeScaleAspectFill;
        [self addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(10);
            make.top.equalTo(self);
            make.width.equalTo(self.mas_height);
            make.height.equalTo(self).offset(-1);
        }];
        _albumImageView = imageView;
        
        UIImageView *arrowView = [[UIImageView alloc] init];
        arrowView.image = [UIImage imageNamed:@"comon_btn_vector"];
        [self addSubview:arrowView];
        [arrowView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-15);
            make.centerY.equalTo(self);
            make.size.mas_equalTo(arrowView.image.size);
        }];
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textColor = [UIColor blackColor];
        [self addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(imageView.mas_right).offset(10);
            make.right.equalTo(arrowView.mas_left).offset(-10);
        }];
        _titleLabel = titleLabel;
        
        UIView *bottomLine = [[UIView alloc] init];
        bottomLine.backgroundColor = UIColorFromRGB(0xdfdfdf);
        [self addSubview:bottomLine];
        [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleLabel);
            make.bottom.equalTo(self).offset(-0.5);
            make.right.equalTo(self);
            make.height.mas_equalTo(0.5);
        }];
    }
    return self;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setImage:(UIImage *)image{
    if (_image != image) {
        _image = image;
        _albumImageView.image = image;
    }
}
- (void)setName:(NSString *)name{
    if (_name != name) {
        _name = name;
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:name attributes:@{NSForegroundColorAttributeName: UIColorFromRGB(0x000000)}];
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"（%ld）",(long)_count] attributes:@{NSForegroundColorAttributeName: UIColorFromRGB(0xa5a5a5)}]];
        _titleLabel.attributedText = string;
    }
}
- (void)setCount:(NSInteger)count{
    if (_count != count) {
        _count = count;
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:_name attributes:@{NSForegroundColorAttributeName: UIColorFromRGB(0x000000)}];
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"（%ld）",(long)count] attributes:@{NSForegroundColorAttributeName: UIColorFromRGB(0xa5a5a5)}]];
        _titleLabel.attributedText = string;
    }
}
@end