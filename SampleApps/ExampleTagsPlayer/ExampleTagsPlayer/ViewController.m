//
//  ViewController.m
//  ExampleTagsPlayer
//
//  Created by Sanna Kallio on 09/05/16.
//  Copyright © 2016 Finwe Ltd. All rights reserved.
//

#import "ViewController.h"
#import <Orion1View.h>


#define MARGIN                     10
#define BUTTON_SIZE                50

enum
{
    SENSORS = 0,
    VR,
    TOUCH,
};
typedef int ControlMode;

@interface ViewController () <Orion1ViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL _isSeeking;
    BOOL _controlsHidden;
    ControlMode _controlMode;
    NSUInteger _scale;
}

@property (nonatomic) Orion1View* orionView;
@property (nonatomic) UISlider  *timeSlider;
@property (nonatomic) UIButton *playPauseButton;
@property (nonatomic) UIButton *muteButton;
@property (nonatomic) UIButton *vrButton;
@property (nonatomic) UILabel *timeLeftLabel;
@property (nonatomic) UIView *bottomBar;
@property (nonatomic) UIActivityIndicatorView *bufferIndicator;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) UILabel *tagSelectedLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    // Create OrionView
    _orionView = [[Orion1View alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _orionView.delegate = self;
    _orionView.overrideSilentSwitch = YES;
    
    
    [self.view addSubview:_orionView];
    
    // License url
    NSString* path = [[NSBundle mainBundle] pathForResource:@"license.key.lic" ofType:nil];
    NSURL *licenseUrl = [NSURL fileURLWithPath:path];
    
    // Video url
    NSURL *videoUrl =  [NSURL URLWithString:@"http://www.finwe.fi/videos/cook_fullhd.mp4"];
    
    // Set video and license url
    [_orionView initVideoWithUrl:videoUrl previewImageUrl:nil licenseFileUrl:licenseUrl];
    
    // Create tag with index 1
    [_orionView createTag:1];
    path = [[NSBundle mainBundle] pathForResource:@"tag" ofType:@"png"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [_orionView setTagAssetURL:1 tagAssetURL:url];
    [_orionView setTagLocation:1 yawAngle:0.0f pitchAngle:0.0f];
    _scale = 2;
    [_orionView setTagScale:1 scale:_scale];
    [_orionView setTagAlpha:1 alpha:1.0f];
    
    _controlMode = SENSORS;
    
    [self prepareView];
}

-(void)prepareView
{
    // Bottom bar
    CGFloat bottomBarH = BUTTON_SIZE + 2 * MARGIN;
    _bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - bottomBarH, self.view.bounds.size.width, bottomBarH)];
    _bottomBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_bottomBar];
    
    // Play/pause button
    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playPauseButton.frame = CGRectMake(0, MARGIN, BUTTON_SIZE, BUTTON_SIZE);
    [_playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [_playPauseButton addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
    [_playPauseButton setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [_bottomBar addSubview:_playPauseButton];
    
    // Time left label
    _timeLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(_bottomBar.frame) - BUTTON_SIZE * 4 - MARGIN, MARGIN, BUTTON_SIZE*2, BUTTON_SIZE)];
    _timeLeftLabel.text = @"0:00 | 0:00";
    _timeLeftLabel.textColor = [UIColor whiteColor];
    _timeLeftLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomBar addSubview:_timeLeftLabel];
    
    // Time slider
    int sliderX = CGRectGetMaxX(_playPauseButton.frame);
    int sliderY = MARGIN;
    int sliderH = BUTTON_SIZE;
    int sliderW = CGRectGetMinX(_timeLeftLabel.frame)-sliderX;
    
    _timeSlider = [[UISlider alloc] initWithFrame:CGRectMake(sliderX, sliderY, sliderW, sliderH)];
    
    [_timeSlider addTarget:self action:@selector(timeSliderDragExit:) forControlEvents:UIControlEventTouchUpInside];
    [_timeSlider addTarget:self action:@selector(timeSliderDragExit:) forControlEvents:UIControlEventTouchUpOutside];
    [_timeSlider addTarget:self action:@selector(timeSliderDragEnter:) forControlEvents:UIControlEventTouchDown];
    [_timeSlider addTarget:self action:@selector(timeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    [_timeSlider setBackgroundColor:[UIColor clearColor]];
    _timeSlider.minimumValue = 0.0;
    _timeSlider.maximumValue = 0.0;
    [_bottomBar addSubview:_timeSlider];
    
    UITapGestureRecognizer *sliderTapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    [_timeSlider addGestureRecognizer:sliderTapGr];
    
    // Vr button
    _vrButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _vrButton.frame = CGRectMake(CGRectGetWidth(_bottomBar.frame) - 2 * BUTTON_SIZE - MARGIN, MARGIN, BUTTON_SIZE, BUTTON_SIZE);
    [_vrButton setImage:[UIImage imageNamed:@"sensors"] forState:UIControlStateNormal];
    [_vrButton addTarget:self action:@selector(controlMode:) forControlEvents:UIControlEventTouchUpInside];
    [_vrButton setContentEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [_bottomBar addSubview:_vrButton];
    
    // Mute button
    _muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _muteButton.frame = CGRectMake(CGRectGetWidth(_bottomBar.frame) - BUTTON_SIZE - MARGIN, MARGIN, BUTTON_SIZE, BUTTON_SIZE);
    [_muteButton setImage:[UIImage imageNamed:@"sound_on"] forState:UIControlStateNormal];
    [_muteButton addTarget:self action:@selector(mute:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomBar addSubview:_muteButton];
    
    // Tap gesture regocnizer
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    tapGr.delegate = self;
    [self.view addGestureRecognizer:tapGr];
    
    // Indicator for buffering state
    _bufferIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _bufferIndicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [self.view addSubview:_bufferIndicator];
    
    [_bufferIndicator startAnimating];
}

/**
 *  Function called when play/pause button selected.
 */
-(void)playPause:(UIButton*)button
{
    if ([_orionView isPaused])
    {
        [_orionView play];
        [_playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
    else
    {
        [_orionView pause];
        [_playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }
}

/**
 *  Function called when mute button selected.
 */
-(void)mute:(UIButton*)button
{
    if (_orionView.volume == 0.0f)
    {
        _orionView.volume = 1.0;
        [_muteButton setImage:[UIImage imageNamed:@"sound_on"] forState:UIControlStateNormal];
    }
    else
    {
        _orionView.volume = 0.0;
        [_muteButton setImage:[UIImage imageNamed:@"sound_off"] forState:UIControlStateNormal];
    }
}

/**
 *  Function called when vr button selected.
 */
-(void)controlMode:(UIButton*)button
{
    if(_controlMode == SENSORS)
    {
        [_vrButton setImage:[UIImage imageNamed:@"vr"] forState:UIControlStateNormal];
        _orionView.vrModeEnabled = YES;
        _controlMode = VR;
    }
    else if (_controlMode == VR)
    {
        [_vrButton setImage:[UIImage imageNamed:@"touch"] forState:UIControlStateNormal];
        _orionView.vrModeEnabled = NO;
        _orionView.sensorsDisabled = YES;
        _controlMode = TOUCH;
    }
    else if (_controlMode == TOUCH)
    {
        [_vrButton setImage:[UIImage imageNamed:@"sensors"] forState:UIControlStateNormal];
        _orionView.sensorsDisabled = NO;
        _controlMode = SENSORS;
    }
}

/**
 *  Function called when time slider dragging started.
 */
- (IBAction) timeSliderDragEnter:(id)sender
{
    _isSeeking = true;
}

/**
 *  Function called when time slider value changed (dragging).
 */
- (IBAction) timeSliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    [self updateTimeLabel:(int)slider.value];
    
}

/**
 *  Function called when time slider dragging ended.
 */
- (IBAction) timeSliderDragExit:(id)sender
{
    
    UISlider *slider = sender;
    [self.orionView seekTo:[slider value]];
    _isSeeking = false;
}

/**
 *  Function called when time slider has been tapped.
 */
- (void)sliderTapped:(UIGestureRecognizer *)g
{
    UISlider* s = (UISlider*)g.view;
    CGPoint pt = [g locationInView: s];
    CGFloat percentage = pt.x / s.bounds.size.width;
    CGFloat delta = percentage * (s.maximumValue - s.minimumValue);
    CGFloat value = s.minimumValue + delta;
    [s setValue:value animated:YES];
    [self.orionView seekTo:value];
    _isSeeking = false;
    
    [self updateTimeLabel:(int)value];
}

/**
 *  Function to update time label.
 */
- (void)updateTimeLabel:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int durationSeconds = (int)_timeSlider.maximumValue % 60;
    int durationMinutes = ((int)_timeSlider.maximumValue/60) % 60;
    _timeLeftLabel.font = [UIFont systemFontOfSize:16];
    _timeLeftLabel.text = [NSString stringWithFormat:@"%d:%02d | %d:%02d",minutes, seconds, durationMinutes, durationSeconds];
}

/**
 *  Function called when tap detected on the screen.
 */
-(void)tapDetected:(UITapGestureRecognizer*)gr
{
    [self showHideControlBars:!_controlsHidden];
}

/**
 *  Function to show or hide control bars.
 */
-(void)showHideControlBars:(BOOL)hide
{
    if (hide == _controlsHidden)
    {
        return;
    }
    
    CGRect bottomFrame = _bottomBar.frame;
    if (hide)
    {
        bottomFrame.origin.y = self.view.bounds.size.height;
    }
    else
    {
        bottomFrame.origin.y = self.view.bounds.size.height - bottomFrame.size.height;
    }
    _controlsHidden = hide;
    [UIView animateWithDuration:0.3f animations:^(void){
        _bottomBar.frame = bottomFrame;
    }];
}


#pragma - Orino1View delegate functions

- (void)orion1ViewVideoDidReachEnd:(Orion1View*)orion1View
{
    [orion1View play:0.0f];
}


- (void)orion1ViewReadyToPlayVideo:(Orion1View*)orion1View
{
    [orion1View play:0.0f];
    [_timeSlider setMaximumValue:_orionView.totalDuration];
}

- (void)orion1ViewDidUpdateProgress:(Orion1View*)orion1View currentTime:(CGFloat)currentTime availableTime:(CGFloat)availableTime totalDuration:(CGFloat)totalDuration
{
    if(_timeSlider.maximumValue != totalDuration)
    {
        [_timeSlider setMaximumValue:totalDuration];
    }
    
    if (!_isSeeking)
    {
        _timeSlider.value = currentTime;
        [self updateTimeLabel:(int)currentTime];
    }
    
    // Move the tag
    [_orionView setTagLocation:1 yawAngle:currentTime  pitchAngle:0.0f];
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

- (void)orion1ViewTagDidSelect:(Orion1View*)orion1View tagIndex:(NSUInteger)tagIndex
{
    // Change the tag image to indicate that it was selected
    NSString *path = [[NSBundle mainBundle] pathForResource:@"finwe" ofType:@"png"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [_orionView setTagAssetURL:1 tagAssetURL:url];
    
    // Create timer to change the tag image back to original
    [self createTimer];
}

- (void)orion1ViewTagDidChangeVRControlState:(Orion1View*)orion1View state:(TagVRControlState)state tagIndex:(NSUInteger)tagIndex
{
    // VR mode states for tag selection
    switch (state) {
        case VR_CONTROL_STATE_TAG_INITIALIZED: // tag selection initiated
        {
            break;
        }
        case VR_CONTROL_STATE_TAG_SELECTING: // tag selection ongoing
        {
            // Set the tag scale bigger to indicate that the selection is ongoing
            _scale += 1;
            [_orionView setTagScale:1 scale:_scale];
            [self createTimer];
            break;
        }
        case VR_CONTROL_STATE_TAG_UNSELECTING: // tag unselection ongoing
        {
            // Set the tag scale smaller to indicate that the unselection is ongoing
            _scale -= 1;
           [_orionView setTagScale:1 scale:_scale];
            [self createTimer];
            break;
        }
        case VR_CONTROL_STATE_TAG_SELECTED: // tag selected
        {
            // Change the tag image to indicate that it was selected
            _scale = 2;
            [_orionView setTagScale:1 scale:_scale];
            NSString *path = [[NSBundle mainBundle] pathForResource:@"finwe" ofType:@"png"];
            NSURL *url = [NSURL fileURLWithPath:path];
            [_orionView setTagAssetURL:1 tagAssetURL:url];
            [self createTimer];
            break;
        }
        default:// case VR_CONTROL_STATE_TAG_OFF
        {
            _scale = 2;
            [_orionView setTagScale:1 scale:_scale];
            break;
        }
    }
    return;
}

/**
 * Function to create timer
 **/
-(void)createTimer
{
    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval: 2.0
                                              target: self
                                            selector:@selector(onTick:)
                                            userInfo: nil repeats:NO];
}

/**
 * Timer selector function
 **/
-(void)onTick:(NSTimer *)timer
{
    // Set tag scale and image back to original
    _scale = 2;
    [_orionView setTagScale:1 scale:_scale];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tag" ofType:@"png"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [_orionView setTagAssetURL:1 tagAssetURL:url];
}

@end
