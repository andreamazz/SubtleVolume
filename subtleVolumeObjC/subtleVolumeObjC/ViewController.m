//
//  ViewController.m
//  subtleVolumeObjC
//
//  Created by iMokhles on 24/03/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import "ViewController.h"
#import "SubtleVolume.h"

@interface ViewController () <SubtleVolumeDelegate> {
    SubtleVolume *volume;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    volume = [[SubtleVolume alloc] initWithStyle:SubtleVolumeStylePlain];
    volume.frame = CGRectMake(10, 70, self.view.frame.size.width-20, 4);
    volume.barTintColor = [UIColor whiteColor];
    volume.barBackgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    volume.animation = SubtleVolumeAnimationFadeIn;
    volume.delegate = self;
    [self.view addSubview:volume];
    [self.view bringSubviewToFront:volume];
    
}

- (void)subtleVolume:(SubtleVolume *)volumeView willChange:(CGFloat)value {
    
    NSLog(@"%f alpha: %f", value, volumeView.alpha);
    
}
- (void)subtleVolume:(SubtleVolume *)volumeView didChange:(CGFloat)value {
    NSLog(@"END %f alpha: %f", value, volumeView.alpha);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
