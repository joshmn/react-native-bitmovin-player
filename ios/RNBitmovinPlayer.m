#import "RNBitmovinPlayer.h"
#import <React/RCTLog.h>
#import <React/RCTView.h>

@implementation RNBitmovinPlayer {
    BOOL _fullscreen;
}

@synthesize player = _player;
@synthesize playerView = _playerView;

double _progress = 0;
BOOL _isFullscreen = NO;
BOOL _finished = NO;

- (void)dealloc {
    [_player destroy];
    
    _player = nil;
    _playerView = nil;
}

- (instancetype)init {
    if ((self = [super init])) {
        _fullscreen = NO;
    }
    return self;
}

-(void)setInitialProgress:(double)initialProgress {
    _progress = initialProgress;
    [_player seek:initialProgress];
}

-(void)setIsFullscreen:(BOOL)isFullscreen {
    _isFullscreen = isFullscreen;
}

- (void)setConfiguration:(NSDictionary *)config {
    BMPPlayerConfiguration *configuration = [BMPPlayerConfiguration new];
    
    if (!config[@"source"] || !config[@"source"][@"url"] || !config[@"offlineSource"]) return;
    
    if (config[@"offlineSource"] == [NSNull null]){
        [configuration setSourceItemWithString:config[@"source"][@"url"] error:NULL];
        
        if (config[@"source"][@"title"]) {
            configuration.sourceItem.itemTitle = config[@"source"][@"title"];
        }        
    } else {
        [BMPOfflineManager initializeOfflineManager];
        BMPOfflineManager *offlineManager = [BMPOfflineManager sharedInstance];
        
        BMPSourceItem *sourceItem = [BMPSourceItem fromJsonData:config[@"offlineSource"][@"source"] error:NULL ];
        
        BMPOfflineSourceItem *offlineSourceItem = [offlineManager createOfflineSourceItemForSourceItem:sourceItem restrictedToAssetCache:true];
        configuration.sourceItem  = offlineSourceItem;
    }
    
    if (config[@"poster"] && config[@"poster"][@"url"]) {
        configuration.sourceItem.posterSource = [NSURL URLWithString:config[@"poster"][@"url"]];
        configuration.sourceItem.persistentPoster = [config[@"poster"][@"persistent"] boolValue];
    }
    
    if (![config[@"style"][@"uiEnabled"] boolValue]) {
        configuration.styleConfiguration.uiEnabled = NO;
    }
    
    if ([config[@"style"][@"systemUI"] boolValue]) {
        configuration.styleConfiguration.userInterfaceType = BMPUserInterfaceTypeSystem;
    }
    
    if (config[@"style"][@"uiCss"]) {
        configuration.styleConfiguration.playerUiCss = [NSURL URLWithString:config[@"style"][@"uiCss"]];
    }
    
    if (config[@"style"][@"supplementalUiCss"]) {
        configuration.styleConfiguration.supplementalPlayerUiCss = [NSURL URLWithString:config[@"style"][@"supplementalUiCss"]];
    }
    
    if (config[@"style"][@"uiJs"]) {
        configuration.styleConfiguration.playerUiJs = [NSURL URLWithString:config[@"style"][@"uiJs"]];
    }
    
    _player = [[BMPBitmovinPlayer alloc] initWithConfiguration:configuration];
    
    [_player addPlayerListener:self];
    
    _playerView = [[BMPBitmovinPlayerView alloc] initWithPlayer:_player frame:self.frame];
    _playerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    _playerView.frame = self.bounds;
    
    [_playerView addUserInterfaceListener:self];

    if ([config[@"style"][@"fullscreenIcon"] boolValue]) {
        _playerView.fullscreenHandler = self;
    }
    
    [self addSubview:_playerView];
    [self bringSubviewToFront:_playerView];
    
    
}

- (NSDictionary *) calculateProgres:(double) currentTime {
    double currentProgress = currentTime / _player.duration;
    double percentage = round(currentProgress * 100);
    
    NSDictionary *response = [NSDictionary dictionaryWithObjectsAndKeys:@"currentTime", currentTime, @"percentage", percentage, nil];
    return response;
}

#pragma mark BMPFullscreenHandler protocol
- (BOOL)isFullscreen {
    return _fullscreen;
}

- (void)onFullscreenRequested {
    _fullscreen = YES;
}

- (void)onFullscreenExitRequested {
    _fullscreen = NO;
}

#pragma mark BMPPlayerListener
- (void)onReady:(BMPReadyEvent *)event {
    [_player seek:_progress];
    _finished = NO;
    
    _onReady(@{
        @"duration": @(_player.duration)
    });
}

- (void)onPlay:(BMPPlayEvent *)event {
    if (_finished) {
        _onReplay(@{});
        _finished = NO;
    } else {
        _onPlay(@{
        @"time": @(event.time),
        });
    }
}

- (void)onPaused:(BMPPausedEvent *)event {
    _onPaused(@{
              @"time": @(event.time),
              });
}

- (void)onTimeChanged:(BMPTimeChangedEvent *)event {
    _progress = event.currentTime;
    
    double currentProgress = event.currentTime / _player.duration;
    double percentage = round(currentProgress * 100);
    
    _onTimeChanged(@{
                @"currentTime": @(event.currentTime),
                @"percentage": @(percentage),
                });
}

- (void)onStallStarted:(BMPStallStartedEvent *)event {
    _onStallStarted(@{});
}

- (void)onStallEnded:(BMPStallEndedEvent *)event {
    _onStallEnded(@{});
}

- (void)onPlaybackFinished:(BMPPlaybackFinishedEvent *)event {
    _finished = YES;
    
    _onPlaybackFinished(@{});
}

- (void)onRenderFirstFrame:(BMPRenderFirstFrameEvent *)event {
    _onRenderFirstFrame(@{});
}

- (void)onError:(BMPErrorEvent *)event {
    _onPlayerError(@{
               @"error": @{
                       @"code": @(event.code),
                       @"message": event.message,
                       }
               });
}

- (void)onMuted:(BMPMutedEvent *)event {
    _onMuted(@{});
}

- (void)onUnmuted:(BMPUnmutedEvent *)event {
    _onUnmuted(@{});
}

- (void)onSeek:(BMPSeekEvent *)event {
    _progress = event.seekTarget;
    
    double currentProgress = event.seekTarget / _player.duration;
    double percentage = round(currentProgress * 100);
    
    if (percentage < 95) {
        _finished = NO;
    }
    
    _onSeek(@{
              @"currentTime": @(event.seekTarget),
              @"percentage": @(percentage),
              @"seekTarget": @(event.seekTarget),
              @"position": @(event.position),
              });
}

- (void)onSeeked:(BMPSeekedEvent *)event {
    _onSeeked(@{});
}

#pragma mark BMPUserInterfaceListener
- (void)onFullscreenEnter:(BMPFullscreenEnterEvent *)event {
    if (_isFullscreen) {
        _onFullscreenExit(@{
            @"currentTime": @(_progress)
        });
    } else {
        _onFullscreenEnter(@{
            @"currentTime": @(_progress)
        });
    }
    
}

- (void)onFullscreenExit:(BMPFullscreenExitEvent *)event {
    if (_isFullscreen) {
        _onFullscreenExit(@{
            @"currentTime": @(_progress)
        });
    } else {
        _onFullscreenEnter(@{
            @"currentTime": @(_progress)
        });
    }
}

- (void)onControlsShow:(BMPControlsShowEvent *)event {
    _onControlsShow(@{});
}

- (void)onControlsHide:(BMPControlsHideEvent *)event {
    _onControlsHide(@{});
}

@end
