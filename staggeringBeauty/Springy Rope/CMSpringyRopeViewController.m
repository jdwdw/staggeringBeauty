//
//  CMSpringyRopeViewController.m
//  DynamicXrayCatalog
//
//  Created by Chris Miles on 30/09/13.
//  Copyright (c) 2013-2014 Chris Miles. All rights reserved.
//
//  Based on CMTraerPhysics demo by Chris Miles, https://github.com/chrismiles/CMTraerPhysics
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMSpringyRopeViewController.h"
#import "CMSpringyRopeView.h"
#import <AVFoundation/AVFoundation.h>
#import "WeixinActivity.h"
#import <GameKit/GameKit.h>

//#import "CMLabelledSwitch.h"

@import GoogleMobileAds;
@interface CMSpringyRopeViewController (){
    
  NSArray *activity;
}

@property (strong, nonatomic) UILabel *fpsLabel;
@property(strong,nonatomic) AVAudioPlayer *player;
//@property(assign,nonatomic) BOOL musicOn;


//Label
@property(strong,nonatomic)UILabel *scoreLabel;
@property(strong,nonatomic)UILabel *rankLabel;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

@end


@implementation CMSpringyRopeViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self authenticateLocalPlayer];
    
    
    activity = @[[[WeixinSessionActivity alloc] init], [[WeixinTimelineActivity alloc] init]];
    
    NSURL *url=[[NSBundle mainBundle]URLForResource:@"backgroundMusic.mp3" withExtension:nil];
    
    self.player=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
        [self.player setNumberOfLoops:1000];
    [self.player prepareToPlay];

    

    
    
    BOOL musicOn=[[NSUserDefaults standardUserDefaults] boolForKey:@"music"];
    
    UIImage *musicImage=[[UIImage alloc]init];

    if (musicOn) {
      musicImage=[UIImage imageNamed:@"musicOnButtonImage.png"];
       [self.player play];
    }else{
      musicImage=[UIImage imageNamed:@"musicOffButtonImage.png"];
    }
    
    NSArray *imageList = @[[UIImage imageNamed:@"shareButtonImage.png"], [UIImage imageNamed:@"borderButtonImage.png"], musicImage, [UIImage imageNamed:@"menuClose.png"]];
    sideBar = [[CDSideBarController alloc] initWithImages:imageList];
    sideBar.delegate = self;
    
    
    
            //加label
            CGPoint anchorPoint = CGPointMake(CGRectGetMinX([[UIScreen mainScreen]bounds])+10, CGRectGetMinY([[UIScreen mainScreen]bounds]));
    
            _scoreLabel=[[UILabel alloc]initWithFrame:CGRectMake(anchorPoint.x, anchorPoint.y, 150, 100)];
            _rankLabel=[[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX([[UIScreen mainScreen]bounds]), anchorPoint.y , 150, 100)];
    
    
            [_rankLabel setFont:[UIFont fontWithName:nil size:25]];
            [_scoreLabel setFont:[UIFont fontWithName:nil size:25]];
        //[_rankLabel setFont:[UIFont fontWithDescriptor:nil size:100]];
        //[_scoreLabel setFont:[UIFont fontWithDescriptor:nil size:30]];
    _scoreLabel.numberOfLines=0;
    _rankLabel.numberOfLines=0;
CGFloat score=[[NSUserDefaults standardUserDefaults] integerForKey:@"Score"];

    NSMutableString *message=[[NSMutableString alloc]init];
    [message appendFormat:@"Score:%d",(int)score];
    self.scoreLabel.text=message;
    
    
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
    GKScore *localPlayerScore=[leaderboardRequest localPlayerScore];
    CGFloat rank=localPlayerScore.rank;
    if (rank==0) {
         rank=[[NSUserDefaults standardUserDefaults] integerForKey:@"Rank"];
        NSLog(@"%f",rank);
    }
    
    NSMutableString *messageRank=[[NSMutableString alloc]init];
    [messageRank appendFormat:@"Rank:%d",(int)rank];
    self.rankLabel.text=messageRank;
             // _rankLabel.text=@"Rank:";
    
    
    _rankLabel.textColor=[UIColor whiteColor];
    _scoreLabel.textColor=[UIColor whiteColor];
    [self.view addSubview:_rankLabel];
    [self.view addSubview:_scoreLabel];
    
    [self.springyRopeView setScoreLabel:self.scoreLabel];
    [self.springyRopeView setRankLabel:self.rankLabel];
    
    
    
    self.bannerView.adSize=kGADAdSizeSmartBannerLandscape;
    self.bannerView.adUnitID=@"ca-app-pub-7330443893787901/7222626674";
    self.bannerView.rootViewController=self;
    
    
    [self.bannerView loadRequest:[GADRequest request]];
    
//
//    self.fpsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//    self.fpsLabel.text = @"00 fps";
//    [self.fpsLabel sizeToFit];
//    
//    CMLabelledSwitch *smoothToggleView = [[CMLabelledSwitch alloc] initWithFrame:CGRectZero];
//    smoothToggleView.text = @"Smooth";
//    [smoothToggleView sizeToFit];
//    [smoothToggleView.embeddedSwitch addTarget:self action:@selector(smoothToggleAction:) forControlEvents:UIControlEventValueChanged];
//    
//    UIBarButtonItem *xrayItem = [[UIBarButtonItem alloc] initWithTitle:@"Xray" style:UIBarButtonItemStyleBordered target:self action:@selector(xrayAction:)];
//
//    NSMutableArray *toolbarItems = [NSMutableArray array];
//    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithCustomView:smoothToggleView]];
//    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
//    if ([self.springyRopeView isDeviceMotionAvailable]) {
//        CMLabelledSwitch *accelerometerToggleView = [[CMLabelledSwitch alloc] initWithFrame:CGRectZero];
//        accelerometerToggleView.text = @"Accel";
//        [accelerometerToggleView sizeToFit];
//        [accelerometerToggleView.embeddedSwitch addTarget:self action:@selector(accelerometerToggleAction:) forControlEvents:UIControlEventValueChanged];
//        
//	[toolbarItems addObject:[[UIBarButtonItem alloc] initWithCustomView:accelerometerToggleView]];
//        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
//    }
//    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithCustomView:self.fpsLabel]];
//    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
//    [toolbarItems addObject:xrayItem];
//
//    self.toolbarItems = toolbarItems;
//    [self.navigationController setToolbarHidden:NO animated:YES];
//    
//    [self.springyRopeView setFpsLabel:self.fpsLabel];
//
//    [self.springyRopeView setDynamicXrayEnabled:NO];
    
//    NSString *tile = NSLocalizedString(@"tile",@"");
//    NSString *theUrl = NSLocalizedString(@"theUrl",@"");
//    NSLog(@"%@",tile);
//    NSLog(@"%@",theUrl);
    
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [sideBar insertMenuButtonOnView:[UIApplication sharedApplication].delegate.window atPosition:CGPointMake(self.view.frame.size.width - 70, 50)];
}

- (CMSpringyRopeView *)springyRopeView
{
    return (CMSpringyRopeView *)self.view;
}
//
//- (void)smoothToggleAction:(UISwitch *)toggleSwitch
//{
//    [self.springyRopeView setSmoothed:toggleSwitch.isOn];
//}
//
//- (void)accelerometerToggleAction:(UISwitch *)toggleSwitch
//{
//    [self.springyRopeView setGravityByDeviceMotionEnabled:toggleSwitch.isOn];
//}
//
//- (void)xrayAction:(__unused id)sender
//{
//    [self.springyRopeView presentDynamicXrayConfigViewController];
//}



- (void)menuButtonClicked:(int)index
{
    // Execute what ever you want
    switch (index) {
        case 0:
            NSLog(@"0");
            [self weChatShare];
            [self becomeFirstResponder];
            break;
        case 1:
            NSLog(@"1");
//            CGFloat score=[[NSUserDefaults standardUserDefaults] integerForKey:@"Score"];
//            NSLog(@"%f",score);
            [self showLeaderboard];
            break;
        case 2:
            NSLog(@"2");
            
        BOOL musicOn=[[NSUserDefaults standardUserDefaults] boolForKey:@"music"];
            if (musicOn) {
             [[NSUserDefaults standardUserDefaults]setBool:false forKey:@"music"];
              [self.player stop];
            }else{
            [[NSUserDefaults standardUserDefaults]setBool:true forKey:@"music"];
            [self.player play];
            }
           [sideBar changetheimage];
           // break;
        default:
            break;
    }
}

-(void)weChatShare{
    NSString *tile = NSLocalizedString(@"tile",@"");
    NSString *theUrl = NSLocalizedString(@"theUrl",@"");
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[tile, [UIImage imageNamed:@"staggeringBeautyIcon57.png"], [NSURL URLWithString:theUrl]] applicationActivities:activity];
    activityView.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePrint];
    //[self presentViewController:activityView animated:YES completion:nil];

    //if iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:activityView animated:YES completion:nil];
    }
    //if iPad
    else {
        // Change Rect to position Popover
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityView];
        [popup presentPopoverFromRect:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/4, 0, 0)inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}




- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [self dismissModalViewControllerAnimated: YES];
}





- (void) authenticateLocalPlayer
{
    NSLog(@"nima");
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *error)
     {
         if (localPlayer.isAuthenticated)
         {
             // Player was successfully authenticated.
             // Perform additional tasks for the authenticated player.
         }
         else
         {
             
         }
     }];
}


- (void) showLeaderboard
{
    // UIViewController *controller=[self getCurrentRootViewController];
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    if (leaderboardController != nil)
    {
        leaderboardController.category=@"slippers.staggeringBeauty_leaderboard";
        leaderboardController.leaderboardDelegate = self;
        [self presentModalViewController: leaderboardController animated: YES];
    }
    
}
-(BOOL)isGameCenterAvaliable{
    Class gcClass=(NSClassFromString(@"GKLocalPlayer"));
    NSString *reqSysVer=@"4.1";
    NSString *currSysVer=[[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported=([currSysVer compare:reqSysVer options:NSNumericSearch]!=NSOrderedAscending);
    return (gcClass&&osVersionSupported);
    
    
}


@end
