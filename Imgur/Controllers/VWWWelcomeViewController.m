//
//  VWWViewController.m
//  Imgur
//
//  Created by Zakk Hoyt on 4/24/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWWelcomeViewController.h"
#import "VWWImgurController.h"
#import "VWWImageCollectionViewCell.h"
#import "VWWRESTEngine.h"
#import "MBProgressHUD.h"


static NSString *VWWSegueWelcomeToMaster = @"VWWSegueWelcomeToMaster";

@interface VWWWelcomeViewController () <UIWebViewDelegate>
@property (nonatomic) BOOL hasAppeared;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@end

@implementation VWWWelcomeViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(self.hasAppeared == NO){
        self.hasAppeared = YES;
        [self checkForExistingSession];
    } else {
        self.signInButton.hidden = NO;
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private

-(void)checkForExistingSession{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.signInButton.hidden = YES;
    [[VWWImgurController sharedInstance]verifyStoredAccountWithCompletionBlock:^(BOOL success) {
        if(success){
            [self performSegueWithIdentifier:VWWSegueWelcomeToMaster sender:self];
        } else {
            self.signInButton.hidden = NO;
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

-(void)authenticateAndGetAccount{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[VWWImgurController sharedInstance] authorizeWithViewController:self completionBlock:^(BOOL success) {
        if(success){
            VWW_LOG_DEBUG(@"Logged in successfully. Account info is in user defaults");
            [self performSegueWithIdentifier:VWWSegueWelcomeToMaster sender:self];
        } else {
            VWW_LOG_ERROR(@"Could not log in");
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];

}


#pragma mark IBActions

- (IBAction)signInButtonTouchUpInside:(id)sender {
    [self authenticateAndGetAccount];
}

@end
