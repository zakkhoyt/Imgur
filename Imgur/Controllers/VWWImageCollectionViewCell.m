//
//  VWWImageCollectionViewCell.m
//  Imgur
//
//  Created by Zakk Hoyt on 4/25/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWImageCollectionViewCell.h"
#import "UIImageView+WebCache.h"
//#import "VWWImage.h"
#import "VWWGallery.h"

@interface VWWImageCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation VWWImageCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

//-(void)setImage:(VWWImage *)image{
//    _image = image;
//
//#if defined(DEBUG)
//    self.backgroundColor = [UIColor randomColor];
//#endif
//    NSURL *url = [self.image squareThumbnailURIForSize:self.bounds.size];
//    VWW_LOG_DEBUG(@"url: %@", url);
//    [self.imageView setImageWithURL:url];
//    
//    
//}
-(void)setGallery:(VWWGallery *)gallery{
    _gallery = gallery;
    
    
#if defined(DEBUG)
    self.backgroundColor = [UIColor randomColor];
#endif
    NSURL *url = [self.gallery squareThumbnailURIForSize:self.bounds.size];
    VWW_LOG_DEBUG(@"url: %@", url);
    [self.imageView setImageWithURL:url];
    
    if(self.gallery.cover){
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@.jpg", self.gallery.cover]];
        [self.imageView setImageWithURL:url];
    } else {
        NSURL *url = [self.gallery squareThumbnailURIForSize:self.bounds.size];
        VWW_LOG_DEBUG(@"url: %@", url);
        [self.imageView setImageWithURL:url];
    }
}
@end
