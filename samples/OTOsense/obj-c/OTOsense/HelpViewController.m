//
//  HelpViewController.m
//  OTOsense
//
//  Created by Akihiro Uehara on 12/06/20.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()
-(void)loadHelpPage;
@end

@implementation HelpViewController
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self loadHelpPage];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Private pages
-(void)loadHelpPage
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
	NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	
	NSString *htmlString = [[NSString alloc] initWithData: 
							[readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	
	self.webView.backgroundColor = [UIColor whiteColor];
	[self.webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:path]];    
}
/* http://iphone-dev.g.hatena.ne.jp/Miyakey/20091017/1255760274
 
 NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
 NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
 
 NSString *htmlString = [[NSString alloc] initWithData: 
 [readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
 
 webView = [[UIWebView alloc] initWithFrame: CGRectMake(0.0f, 10.0f, 320.0f, 380.0f)];
 webView.backgroundColor = [UIColor whiteColor];
 [self.webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:path]];
 
 [window addSubview:webView];
 
 [htmlString release]; */

@end
