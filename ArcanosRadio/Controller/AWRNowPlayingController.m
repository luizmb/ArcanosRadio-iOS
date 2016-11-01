#import "AWRNowPlayingController.h"
#import "AWRArcanosMediaPlayer.h"
#import "AWRNowPlayingView.h"
#import "AWRNowPlayingViewModel.h"
#import "AWRMetadataFactory.h"
#import "PXPromise.h"

NSString *const kStreamingUrlConfigKey = @"iphoneStreamingUrl";

@interface AWRNowPlayingController () <AWRArcanosMediaPlayerDelegate, AWRNowPlayingViewDelegate>

@property(strong, nonatomic) AWRArcanosMediaPlayer *arcanosRadio;
@property(strong, nonatomic) NSString *streamingUrl;
@property(readonly, nonatomic) AWRNowPlayingView *nowPlayingView;
@property(atomic, nullable, strong) AWRNowPlayingViewModel *viewModel;
@end

@implementation AWRNowPlayingController

- (AWRNowPlayingView *)nowPlayingView {
    return (AWRNowPlayingView *)self.view;
}

- (instancetype)init {
    self = [super initWithNibName:@"AWRNowPlayingView" bundle:nil];
    if (self) {
        self.viewModel = [[AWRNowPlayingViewModel alloc] init];

        __weak typeof(self)weakSelf = self;
        [[AWRMetadataFactory createMetadataStore] readConfig:kStreamingUrlConfigKey]
        .then(^id<PXPromise>(id<PXSuccessfulPromise> finishedPromise) {
            weakSelf.streamingUrl = finishedPromise.result;
            return [PXNoMorePromises new];
        });
    }
    return self;
}

- (void)setStreamingUrl:(NSString *)streamingUrl {
    _streamingUrl = streamingUrl;
    if (_streamingUrl) {
        _arcanosRadio = [[AWRArcanosMediaPlayer alloc] initWithUrl:_streamingUrl];
        _arcanosRadio.delegate = self;
        [_arcanosRadio prepare];
        [_arcanosRadio play];
    }
}

- (void)metadataDidChangeTheSong:(NSString *)song artist:(NSString *)artist albumArt:(UIImage *)albumArt {
    self.viewModel.songName = song;
    self.viewModel.artistName = artist;
    self.viewModel.albumArt = albumArt;
    self.viewModel.lyrics = @"";
    [self.nowPlayingView renderModel:self.viewModel];
}

- (void)metadataDidFinishDownloadingAlbumArt:(UIImage *)albumArt {
    self.viewModel.albumArt = albumArt;
    [self.nowPlayingView renderModel:self.viewModel];
}

- (void)metadataDidFinishDownloadingLyrics:(NSString *)lyrics {
    self.viewModel.lyrics = lyrics;
    [self.nowPlayingView renderModel:self.viewModel];
}

- (void)didStartPlaying {
    [self.nowPlayingView setStatusPlaying];
}

- (void)didStopPlaying {
    [self.nowPlayingView setStatusStopped];
}

- (void)didStartBuffering {
    [self.nowPlayingView setStatusBuffering];
}

- (void)beginReceivingRemoteControlEvents {
    [self becomeFirstResponder];
}

- (IBAction)play:(id)sender {
    [self.arcanosRadio play];
}

- (IBAction)stop:(id)sender {
    [self.arcanosRadio stop];
}

- (void)playButtonPressed {
    [self.arcanosRadio togglePlayPause];
}

- (void)muteButtonPressed {
    [self.arcanosRadio toggleMute];
    if (self.arcanosRadio.isMuted) {
        [self.nowPlayingView setVolume:0.0];
    } else {
        [self.nowPlayingView setVolume:self.arcanosRadio.currentVolume];
    }
}

- (void)shareButtonPressed {
    if (self.delegate) {
        [self.delegate userDidSelectShare];
    }
}

- (void)aboutButtonPressed {
    if (self.delegate) {
        [self.delegate userDidSelectAbout];
    }
}

- (void)settingsButtonPressed {
    if (self.delegate) {
        [self.delegate userDidSelectSettings];
    }
}

- (void)volumeChangedTo:(float)percentage {
    [self.arcanosRadio setVolumeTo:percentage];
}

- (void)heavyMetalButtonPressed {
    float newVolume = MIN(self.arcanosRadio.currentVolume * 1.1, 1.0);
    [self.arcanosRadio setVolumeTo:newVolume];
    [self.nowPlayingView setVolume:newVolume];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nowPlayingView.delegate = self;
    [self.nowPlayingView renderModel:self.viewModel];
    [self.nowPlayingView setVolume:1.0];
}

- (void)viewDidUnload {
    [self.arcanosRadio stop];
    [super viewDidUnload];
}

@end
