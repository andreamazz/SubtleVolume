//
//  SubtleVolume.m
//  subtleVolumeObjC
//
//  Created by iMokhles on 24/03/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import "SubtleVolume.h"

MPVolumeView *volume = [[MPVolumeView alloc] initWithFrame:CGRectZero];
UIView *overlay = [[UIView alloc] init];
CGFloat volumeLevel = 0;

@implementation SubtleVolume

- (instancetype)initWithStyle:(SubtleVolumeStyle)style frame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        self.style = style;
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(SubtleVolumeStyle)style {
    return [self initWithStyle:style frame:CGRectZero];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init {
    self = nil;
    NSAssert(false, @"To init this class please use the designated initializer: initWithStyle or initWithStyle:frame:");
    return nil;
}

- (void)setup {
    @try {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    } @catch (NSException *e) {
        NSLog(@"Unable to initialize AVAudioSession");
    }
    [self updateVolume:[[AVAudioSession sharedInstance] outputVolume] animated:NO];
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew  context:NULL];
    [volume setVolumeThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [volume setUserInteractionEnabled:NO];
    [volume setAlpha:0.0001];
    [volume setShowsRouteButton:NO];
    
    [self addSubview:volume];
    
    [self addSubview:overlay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    overlay.frame = self.frame;
    overlay.frame = CGRectMake(0, 0, self.frame.size.width*volumeLevel, self.frame.size.height);
    
    self.backgroundColor = self.barBackgroundColor;
    overlay.backgroundColor = self.barTintColor;
    
}
- (void)updateVolume:(CGFloat)value animated:(BOOL)animated {
    [self.delegate subtleVolume:self willChange:value];
    volumeLevel = value;
    
    [UIView animateWithDuration:animated?0.1:0 animations:^{
        CGRect rectOverlayView = overlay.frame;
        CGFloat overlyWidth = self.frame.size.width * volumeLevel;
        rectOverlayView.size.width = overlyWidth;
        overlay.frame = rectOverlayView;
    }];
    
    if (!animated) {
        self.alpha = 0.0001;
    }
    [UIView animateKeyframesWithDuration:animated?2:0 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.2 animations:^{
            switch (self.animation) {
                case SubtleVolumeAnimationNone:
                    break;
                case SubtleVolumeAnimationFadeIn:
                    self.alpha = 1;
                    break;
                case SubtleVolumeAnimationSlideDown:
                    self.alpha = 1;
                    self.transform = CGAffineTransformIdentity;
                    break;
                default:
                    break;
            }
        }];
        [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
            switch (self.animation) {
                case SubtleVolumeAnimationNone:
                    break;
                case SubtleVolumeAnimationFadeIn:
                    self.alpha = 0.0001;
                    break;
                case SubtleVolumeAnimationSlideDown:
                    self.alpha = 0.0001;
                    self.transform = CGAffineTransformMakeTranslation(0, -self.frame.size.height);
                    break;
                default:
                    break;
            }
        }];
    } completion:^(BOOL finished) {
        [self.delegate subtleVolume:self didChange:value];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqual:@"outputVolume"]) {
        CGFloat value = [change[@"new"] floatValue];
        [self updateVolume:value animated:YES];
    } else {
        return;
    }
    
}

@end
