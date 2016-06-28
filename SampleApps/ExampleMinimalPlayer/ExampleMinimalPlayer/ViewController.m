//
//  ViewController.m
//  ExampleMinimalPlayer
//
//  Created by Finwe Ltd on 18/06/15.
//  Copyright (c) 2015 Finwe Ltd. All rights reserved.
//

/**
 * ExampleMinimalPlayer implements a minimal Orion1 video player. It plays
 * a video file from url using Orion1View default settings.
 *
 * Features:
 * - Plays one hardcoded 360x180 equirectangular video
 * - Auto-starts playback on load
 * - Stops after playback is finished
 * - Sensor fusion (acc+mag+gyro+touch)
 * - Panning (gyro, swipe)
 * - Zooming (pinch)
 * - Fullscreen view locked to landscape
 */


#import "ViewController.h"
#import <Orion1View.h>

@interface ViewController () <Orion1ViewDelegate>

@property (nonatomic) Orion1View* orionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated
{
    _orionView = [[Orion1View alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _orionView.delegate = self;
    
    [self.view addSubview:_orionView];
    
    // License url
    NSString* path = [[NSBundle mainBundle] pathForResource:@"license.key.lic" ofType:nil];
    NSURL *licenseUrl = [NSURL fileURLWithPath:path];
    
    // Video url
    NSURL *videoUrl =  [NSURL URLWithString:@"http://www.finwe.fi/videos/cook_fullhd.mp4"];
    
    // Set video and license url
    [_orionView initVideoWithUrl:videoUrl previewImageUrl:nil licenseFileUrl:licenseUrl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma Orion1View delegate functions
- (void)orion1ViewVideoDidReachEnd:(Orion1View*)orion1View
{
}


- (void)orion1ViewReadyToPlayVideo:(Orion1View*)orion1View
{
    [orion1View play:0.0f];
}

- (void)orion1ViewDidUpdateProgress:(Orion1View*)orion1View currentTime:(CGFloat)currentTime availableTime:(CGFloat)availableTime totalDuration:(CGFloat)totalDuration
{
    
}

- (void)orion1ViewDidChangeBufferingStatus:(Orion1View*)orion1View buffering:(BOOL)buffering
{
    
}


@end
