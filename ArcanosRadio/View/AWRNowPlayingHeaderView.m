#import "AWRNowPlayingHeaderView.h"
#import "AWRAvatarImageView.h"
#import "AWRMergeImageView.h"
#import "FXBlurView.h"
#import "UIImage+Resize.h"

const int kDefaultMargin                            = 8;
const float kAvatarBorder                           = 4.0;
const float kAvatarBorderOpacity                    = 0.35;
const float kAvatarCornerRadius                     = 10.0;
static NSString *const kStatusBarTappedNotification = @"StatusBarTappedNotification";

@interface AWRNowPlayingHeaderView ()

@property (weak, nonatomic) IBOutlet AWRMergeImageView *backgroundAlbumArt;
@property (weak, nonatomic) IBOutlet AWRAvatarImageView *albumArtIcon;
@property (weak, nonatomic) IBOutlet UIStackView *metadataContainer;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (strong, nonatomic) NSDictionary *textEffects;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *metadataVerticalCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusBarBackgroundConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconVerticalConstraint;
@end

@implementation AWRNowPlayingHeaderView

- (float)maximumHeight {
    // returns WIDTH, because height can expand beyond the maximum
    return self.superview.bounds.size.width;
}

- (float)minimumHeight {
    return self.albumArtIcon.bounds.size.height + kDefaultMargin * 2 + self.statusBarHeight;
}

- (float)deltaHeight {
    return self.maximumHeight - self.minimumHeight;
}

- (float)statusBarHeight {
    if (@available(iOS 11.0, *)) {
        return self.safeAreaInsets.top;
    } else {
        return 20.0f;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    float currentHeight              = MIN(self.frame.size.height, self.maximumHeight);
    float progress                   = (self.maximumHeight - currentHeight) / self.deltaHeight;
    self.backgroundAlbumArt.progress = progress;
    self.albumArtIcon.alpha          = progress;

    CATransform3D horizontalOffsetEffect = CATransform3DIdentity;
    horizontalOffsetEffect               = CATransform3DTranslate(horizontalOffsetEffect, (1.0 - progress) * 12.0, 0, 0);
    self.albumArtIcon.layer.transform    = horizontalOffsetEffect;

    self.statusBarBackgroundConstraint.constant = self.statusBarHeight;
    self.iconVerticalConstraint.constant        = self.statusBarHeight / 2.0f;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarTappedAction:)
                                                 name:kStatusBarTappedNotification
                                               object:nil];
    [self emptyFields];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStatusBarTappedNotification object:nil];
}

- (void)statusBarTappedAction:(NSNotification *)notification {
    [self.delegate didTapStatusBar];
}

- (void)emptyFields {
    self.songLabel.text   = @"";
    self.artistLabel.text = @"";
}

- (void)renderModel:(AWRNowPlayingViewState *)model {
    NSString *songName              = model.songName ?: @"";
    NSString *artistName            = model.artistName ?: @"";
    self.songLabel.attributedText   = [[NSAttributedString alloc] initWithString:songName attributes:self.textEffects];
    self.artistLabel.attributedText = [[NSAttributedString alloc] initWithString:artistName attributes:self.textEffects];

    if (!model.albumArt) {
        return;
    }

    self.backgroundAlbumArt.imageStart = [model.albumArt convertToSquareWithSideLength:self.maximumHeight];
    self.backgroundAlbumArt.imageEnd =
        [self.backgroundAlbumArt.imageStart blurredImageWithRadius:22.0
                                                        iterations:2
                                                         tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]];

    self.albumArtIcon.image              = [model.albumArt convertToSize:self.albumArtIcon.frame.size];
    UIColor *borderColor                 = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:kAvatarBorderOpacity];
    self.albumArtIcon.layer.borderColor  = borderColor.CGColor;
    self.albumArtIcon.layer.cornerRadius = kAvatarCornerRadius;
}

- (NSDictionary *)textEffects {
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:1.0f];
    [shadow setShadowColor:[UIColor darkGrayColor]];
    [shadow setShadowOffset:CGSizeMake(0, 1.0f)];

    if (!_textEffects) {
        _textEffects = @{NSShadowAttributeName : shadow};
    }
    return _textEffects;
}

- (float)metadataOffset {
    return self.metadataVerticalCenterConstraint.constant;
}

- (void)setMetadataOffset:(float)metadataOffset {
    self.metadataVerticalCenterConstraint.constant = metadataOffset;
}

- (float)metadataAlpha {
    return self.metadataContainer.alpha;
}

- (void)setMetadataAlpha:(float)metadataAlpha {
    self.metadataContainer.alpha = metadataAlpha;
}

@end
