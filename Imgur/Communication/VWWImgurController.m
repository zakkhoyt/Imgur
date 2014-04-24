//
//  VWWImgurController.m
//  Imgur
//
//  Created by Zakk Hoyt on 4/23/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWImgurController.h"
#import "VWWImgurControllerConfig.h"
#import "VWWRESTConfig.h"
#import "NSString+URLEncoding.h"
#import "VWWRESTEngine.h"
// Type of authentication
typedef enum {
    VWWImgurControllerAuthTypeToken = 0,
    VWWImgurControllerAuthTypePin,
    VWWImgurControllerAuthTypeCode,
} VWWImgurControllerAuthType;

static VWWImgurController *instance;

@interface VWWImgurController () <UIWebViewDelegate>
@property (nonatomic, strong) VWWBoolBlock authorizeBlock;
@property (nonatomic) VWWImgurControllerAuthType authType;
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation VWWImgurController

+(VWWImgurController*)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VWWImgurController alloc]init];
    });
    return instance;
}

-(id)init{
    self = [super init];
    if(self){
        _authType = VWWImgurControllerAuthTypeCode;
    }
    return self;
}

-(void)authorizeWithViewController:(UIViewController*)viewController completionBlock:(VWWBoolBlock)completionBlock{
    // Called in webview delegate
    self.authorizeBlock = [completionBlock copy];
    
    // Build query string and present to user in a webview.
    // https://api.imgur.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&response_type=REQUESTED_RESPONSE_TYPE&state=APPLICATION_STATE
    
    NSString *responseType;
    if(self.authType == VWWImgurControllerAuthTypeToken){
        responseType = @"token";
    } else if(self.authType == VWWImgurControllerAuthTypePin){
        responseType = @"pin";
    } else if(self.authType == VWWImgurControllerAuthTypeCode){
        responseType = @"code";
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/"
                           @"%@?"
                           @"client_id=%@&"
                           @"response_type=%@&"
                           @"state=%@",
                           [VWWRESTConfig sharedInstance].serviceURLString,
                           [VWWRESTConfig sharedInstance].authorizeURI,
                           VWWImgurControllerConfigClientID,
                           responseType,
                           @"auth"];

    
    VWW_LOG_DEBUG(@"urlString: %@", urlString);

//    // Clear all cookies
//    NSHTTPCookie *cookie;
//    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    for (cookie in [storage cookies]) {
//        [storage deleteCookie:cookie];
//    }
//    [[NSUserDefaults standardUserDefaults] synchronize];

//    // Flush cache
//    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    self.webView = [[UIWebView alloc]initWithFrame:viewController.view.frame];
    self.webView.delegate = self;
    NSURL *url = [NSURL URLWithString:urlString];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [viewController.view addSubview:self.webView];
    
    VWW_LOG_TRACE;
}

-(void)authorizationSucceeded:(BOOL)success{
    // Remove web view from view controller
    [self.webView removeFromSuperview];
    _webView = nil;
    
    // Fire completion block
    if(self.authorizeBlock == nil) return;
    self.authorizeBlock(success);
    _authorizeBlock = nil;
}


- (NSDictionary *)parseQuery:(NSString *)string {
    NSArray *components = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary *receivedDict = [NSMutableDictionary dictionary];
    for (NSString *component in components) {
        NSArray *parts = [component componentsSeparatedByString:@"="];
        if (parts.count == 2) {
            receivedDict[parts[0]] = parts[1];
        }
    }
    return receivedDict;
}


#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    

    VWW_LOG_DEBUG(@"request: %@", request);
    VWW_LOG_DEBUG(@"navType: %ld", (long)navigationType);

    
    if(self.authType == VWWImgurControllerAuthTypeToken){
        // https://imgur.com/?state=auth#access_token=b1456e64f2755122efa0c2beba20d8220bd07f34&expires_in=3600&token_type=bearer&refresh_token=3da76301ec53e2f516e7c7704f7488a481e4b7a0&account_username=sneeden
    } else if(self.authType == VWWImgurControllerAuthTypePin){
    
    } else if(self.authType == VWWImgurControllerAuthTypeCode){
        // Once user logs in we will get their goodies in the ridirect URL. Example:
        // https://imgur.com/?state=auth&code=860381d0651a8c24079aa13c8732567d8a3f7bab
        NSString *responseString = [[[request URL] absoluteString] URLDecodedString];// request.URL.absoluteString;
        if ([responseString rangeOfString:@"code="].location != NSNotFound) {
            NSDictionary *responseDictionary = [self parseQuery:responseString];
            NSString *code = responseDictionary[@"code"];
            VWW_LOG_DEBUG(@"Code: %@", code);
            
            
            VWWCodeForm *form = [[VWWCodeForm alloc]init];
            form.code = code;
            form.clientID = VWWImgurControllerConfigClientID;
            form.clientSecret = VWWImgurControllerConfigSecret;
            form.grantType = @"authorization_code";
            [[VWWRESTEngine sharedInstance] getTokensWithForm:form completionBlock:^(VWWToken *token) {
                // Write access token to NSUserDefaults
                [[NSUserDefaults standardUserDefaults] setObject:token.accessToken forKey:VWWTokenAccessTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self authorizationSucceeded:YES];
            } errorBlock:^(NSError *error, NSString *description) {
                [self authorizationSucceeded:NO];
            }];
            
        }
        //    NSString *URLString = [[[request URL] absoluteString] URLDecodedString];
        //    NSLog(@"webView shouldStartLoadWithRequest: %@", URLString);
        //
        //    if ([URLString rangeOfString:kTwitterCallbackURL].location == NSNotFound) return YES;
        //
        //    [webView stopLoading];
        //
        //    NSDictionary *response = [self parseQuery:[[URLString componentsSeparatedByString:@"?"] lastObject]];
        //    [self getAccessTokenWithToken:response[@"oauth_token"] verifier:response[@"oauth_verifier"]];

    }
    
    
    
    VWW_LOG_TRACE;
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    VWW_LOG_TRACE;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    VWW_LOG_TRACE;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    

    VWW_LOG_TRACE;
}
@end