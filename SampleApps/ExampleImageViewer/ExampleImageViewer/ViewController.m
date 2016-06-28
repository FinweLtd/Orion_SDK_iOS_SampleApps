//
//  ViewController.m
//  ExampleImageViewer
//
//  Created by Finwe Ltd on 18/06/15.
//  Copyright (c) 2015 Finwe Ltd. All rights reserved.
//

/**
 * This is an example of Orion1 image viewer.
 *
 * Features:
 * - Plays one hardcoded 360x180 equirectangular image
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
    
    // Photo url
    NSURL *photoUrl =  [NSURL URLWithString:@"http://www.finwe.fi/photo/Orion360_HD1080.jpg"];
    
    // Set photo and license url
    [_orionView initImageWithUrl:photoUrl licenseFileUrl:licenseUrl];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
