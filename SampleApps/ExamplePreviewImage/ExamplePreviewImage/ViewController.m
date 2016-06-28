//
//  ViewController.m
//  ExamplePreviewImage
//
//  Created by Finwe Ltd on 18/06/15.
//  Copyright (c) 2015 Finwe Ltd. All rights reserved.
//

/**
 * ExamplePreviewImage is an Orion1 video player with a preview image. It plays
 * a video file from url, and allows cross-fading to/from a preview image
 * whose specifications match with the video.
 *
 * Features:
 * - Plays one hardcoded 360x180 equirectangular video
 * - Auto-starts playback on load
 * - Restarts after playback is finished (loop)
 * - Preview image with crossfade to/from video
 * - Panning (gyro, swipe)
 * - Zooming (pinch)
 * - Fullscreen, landscape
 */

#import "ViewController.h"
#import <Orion1View.h>

@interface ViewController () <Orion1ViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) Orion1View* orionView;
@property (nonatomic) UILabel* label;
@property (nonatomic) UIActivityIndicatorView *bufferIndicator;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    _orionView = [[Orion1View alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _orionView.delegate = self;
    
    [self.view addSubview:_orionView];
    
    // License url
    NSString* path = [[NSBundle mainBundle] pathForResource:@"license.key.lic" ofType:nil];
    NSURL *licenseUrl = [NSURL fileURLWithPath:path];
    
    // Video url
    NSURL *videoUrl =  [NSURL URLWithString:@"http://www.finwe.fi/videos/cook_fullhd.mp4"];
    
    NSURL *prevImageUrl = [NSURL URLWithString:@"http://www.finwe.fi/photo/Orion360_HD1080.jpg"];
    
    // Set video and license url
    [_orionView initVideoWithUrl:videoUrl previewImageUrl:prevImageUrl licenseFileUrl:licenseUrl];
    _orionView.previewImageMode = YES;
    
    // Tap gesture regocnizer
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    tapGr.delegate = self;
    [self.view addGestureRecognizer:tapGr];
    
    // Indicator for buffering state
    _bufferIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _bufferIndicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [self.view addSubview:_bufferIndicator];
    
    
    // Add label in the middle of the screen
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    _label.text = @"Tap to start the video";
    _label.backgroundColor = [UIColor clearColor];
    _label.textColor = [UIColor whiteColor];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.font = [UIFont boldSystemFontOfSize:20];
    _label.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);;
    _label.alpha = 0.0f;
    [self.view addSubview:_label];
    
    [UIView animateWithDuration:1.0f
                     animations:^(void) {
                         _label.alpha = 1.0f;
                     }
                     completion:^ (BOOL finished) {}];
}

/**
 *  Function called when tap detected on the screen.
 */
-(void)tapDetected:(UITapGestureRecognizer*)gr
{
    if(_orionView.previewImageMode == NO)
    {
        _orionView.previewImageMode = YES;
        [_bufferIndicator stopAnimating];
        [UIView animateWithDuration:1.0f
                         animations:^(void) {
                             _label.alpha = 1.0f;
                         }
                         completion:^ (BOOL finished) {}];
    }
    else
    {
        _orionView.previewImageMode = NO;
        [_bufferIndicator startAnimating];
        _label.alpha = 0.0f;
    }
}


# pragma Orion1View delegate functions
- (void)orion1ViewVideoDidReachEnd:(Orion1View*)orion1View
{
    [orion1View play:0.0f];
    _orionView.previewImageMode = YES;
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
    if (buffering && ![_bufferIndicator isAnimating])
    {
        [_bufferIndicator startAnimating];
    }
    else if (!buffering && [_bufferIndicator isAnimating])
    {
        [_bufferIndicator stopAnimating];
    }
}



@end
