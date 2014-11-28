//
//  ViewController.h
//  wave
//
//  Created by Yvan Scher on 9/19/14.
//  Copyright (c) 2014 Yvan Scher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UITextView *textDisplayField;
@property (nonatomic) IBOutlet UIWebView *webView;

-(IBAction) handleSearchButtonPressed:(id)sender;

- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void) createWebViewWithHTML:(NSString *)html;


@end

