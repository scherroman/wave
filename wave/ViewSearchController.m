//
//  ViewController.m
//  wave
//
//  Created by Yvan Scher on 9/19/14.
//  Copyright (c) 2014 Yvan Scher. All rights reserved.
//

#import "ViewSearchController.h"
#import "MultipeerConnectivity/MultipeerConnectivity.h"

@interface ViewController () <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

//SEEDER AND LEECHER FOR ADVERTISER/SEARCHER
@property (nonatomic) MCNearbyServiceAdvertiser *autoadvertiser;
@property (nonatomic) MCNearbyServiceBrowser *autobrowser;
@property (nonatomic) MCPeerID *localpeerID;
@property (nonatomic) MCSession *session;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSInteger receivedInvite;
@property (nonatomic) NSMutableData* responseData; // ROMAN ADD //NSData -> NSMutableData changed by Roman

@end

@implementation ViewController

//ADVERTISE AND CONNECT TO PEERS AUTOMATICALLY
- (void)viewDidLoad {
    
    [super viewDidLoad];
    //_receivedInvite = 0;
    //THIS NEXT PART STARTS ADVERTISING
    NSString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    _displayName = [NSString stringWithFormat: @"Wave-Device-%@", uniqueIdentifier];
    _localpeerID = [[MCPeerID alloc] initWithDisplayName: _displayName];
    _session = [[MCSession alloc] initWithPeer:_localpeerID];
    _session.delegate = self;
    
    //WHAT IS DISCOVERY INFO???
    _autoadvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_localpeerID discoveryInfo:nil serviceType:@"wave-msg"];
    _autoadvertiser.delegate = self;
    [_autoadvertiser startAdvertisingPeer];
    
    //THIS NEXT PART SEARCHES FOR OTHER PEERS WHO ARE ADVERTISING THEMSELVES.
    _autobrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:_localpeerID serviceType:@"wave-msg"];
    _autobrowser.delegate = self;
    [_autobrowser startBrowsingForPeers];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        
    _textDisplayField.text = [NSString stringWithFormat:@"VIEW DID LOAD-MYPID:%@", _displayName];
    //});
}

//BROWSER DELEGATE METHOD THAT IDENTIFIES WHEN WE HAVE FOUND A PEER, GETS CALLED WHEN PEER IS FODUN BY AUTOBROWSER OBJECT
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    
    
   // dispatch_async(dispatch_get_main_queue(), ^{
        
        _textDisplayField.text = @"FOUND PEER";

    //});
    
    //CONNECT TO THE PEER AND INVITE TO SESSION
    //NSString *contextString = @"wave-msg";
    //NSData *context = [contextString dataUsingEncoding:NSUTF8StringEncoding]; //ARBITRARY CONTEXT (EXTRA DATA PASSED TO USER) here = to serviceType
    
    //MAKE SURE WE HAVE A SESSSION IF WE DONT MAKE ONE.
    if (!_session) {
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            
            _textDisplayField.text = @"FOUND PEER SESSION REMAKE";
            
        //});

        MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:_displayName];
        _session = [[MCSession alloc] initWithPeer:peerID];
        _session.delegate = self;
    }
    
    [_autobrowser invitePeer:peerID toSession:_session withContext:nil timeout:5.0];
}

//ADVERTISING DELEGATE METHOD THAT IDENTIFIES WHEN WE RECEIVE AND INVITE FROM A PEER
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler{
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        
        _textDisplayField.text = @"RECEIVED INVITATION FROM PEER";
        
    //});
    //ACCEPTS THE INVITATION OF THE PEER BY CONNECTING TO THEM
    invitationHandler(YES, _session);
    [_autoadvertiser stopAdvertisingPeer];
}

- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler{
    
    certificateHandler(YES);
}

// RECEIVED DATA FROM REMOTE PEER - GONNA DISPLAY DATA IN OUR TEXTFIELD HERE
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _textDisplayField.text = @"RECEIVED DATA";
         NSString *message =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        //IF SPECIAL HEADER INDICATING ORIGINAL SENDER IS FOUND (ORIGINAL SEARCHER)
        //NOTE THE ! OPERATOR
        if (!([message rangeOfString:@"wave-msg"].location == NSNotFound)){
            
            message = [message stringByReplacingOccurrencesOfString:@"wave-msg" withString:@""];
            
            //ROMAN ADD
            _responseData = [NSMutableData new];
            
            NSString *wiki = @"http://en.wikipedia.org/wiki/";
            NSString *searchTerm = message; //USER INPUT from first screen
            NSString *search_Term = [searchTerm stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            NSString *wikiURL = [wiki stringByAppendingString:search_Term];
            NSURL *url = [NSURL URLWithString:wikiURL];
            
            // create get request then call
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
            [request setHTTPMethod:@"GET"];
            
            NSURLConnection *connect = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url MIMEType:@"text/html" expectedContentLength:-1 textEncodingName:nil];
            
            NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];

            [self connection:connect didReceiveResponse:response];
            NSData *dataToAppend = returnData;
            [self connection:connect didReceiveData:dataToAppend]; //SHOULD didReceiveData really be set to _responseData?
            
            NSError *error = nil;
            [self createWebViewWithHTML:nil];
            
            //connectedPeers IS THE ARRAY OF PEERS TO WHOM WE ARE CONNECTED (SET AUTOMATICALLY)
            if([_session sendData:_responseData toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:&error]){
                
                
                    
                _textDisplayField.text = @"DATA SENT BACK FROM THIS PHONE";
                
            }
            else{
                
                _textDisplayField.text = [NSString stringWithFormat:@"%@", error];
                NSLog(@"%@",error);
            }
        }
        else{
            
            message = [NSString stringWithFormat:@"%@%@", @"return STRING", message];
            _textDisplayField.text = @"DATA RECEIVED BACK FROM THIS PHONE TO MAKE WEBVIEW";
            [self createWebViewWithHTML:message];
        }
    });
}

//SENDS
-(void)handleSearchButtonPressed:(id)sender{
    
    NSString *searchText = _searchBar.text;
    searchText = [NSString stringWithFormat:@"%@%@", @"wave-msg", searchText]; //special identifier for searching message
    NSData *data = [searchText dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    
    //connectedPeers IS THE ARRAY OF PEERS TO WHOM WE ARE CONNECTED (SET AUTOMATICALLY)
    if([_session sendData:data toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:&error]){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
             _textDisplayField.text = @"DATA SEND FROM THIS PHONE";
        });
    }
    else{
        
        _textDisplayField.text = [NSString stringWithFormat:@"%@", error];
        NSLog(@"%@",error);
    }
}

//BROWSER DELEGATE METHOD THAT IDENTIFIES WHEN WE CAN NO LONGER LOCATE A PEER
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        
        _textDisplayField.text = @"LOST PEER";
        
    //});
}

//REMOTE PEER HAS ALTERED ITS STATE SOMEHOW
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
    if(state == MCSessionStateNotConnected){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _textDisplayField.text = @"WE ARE NOT CONNECTED";
            
        });
    }
    
    if(state == MCSessionStateConnected){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _textDisplayField.text = @"WE ARE CONNECTED";
            
        });
    }
}

//ROMAN ADD                     ROMAN ADD                       ROMAN ADD                   ROMAN ADDD


- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    
    // 'clean up' after NSURLConnection
    // responseString holds html data (encoded from responseData return)
    NSString* responseString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    [self createWebViewWithHTML:responseString];
}

// initialize responseData
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    _responseData = [NSMutableData alloc]; // INITIALIZATION CHANGED BY ROMAN
}

// fill responseData with data returned from get
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [_responseData appendData:data];
}

// sheeit something is wrong
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    NSLog(@"couldn't complete http request");
}

// code for displaying HTML as webpage
// inside of UIWebView
- (void) createWebViewWithHTML:(NSString *)html{
    
    //instantiate the web view
    //UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    
    //make the background transparent
    [_webView setBackgroundColor:[UIColor clearColor]];
    
    // maybe?
    _webView.opaque = NO;
    
    //pass the string to the webview
    [_webView loadHTMLString:html baseURL:nil];
    //[webView loadHTMLString:[html description] baseURL:nil];
    //add it as subview to main window
    [self.view addSubview:_webView];
    
    CGRect f = self.webView.bounds;
    f.origin.x = 240;
    f.origin.y = 371;
    
    
}

//ROMAN ADD                         ROMAN ADD                   ROMAN ADD                   ROMAN ADD*/


/******
 UNUSED/UNIMPLEMENTED SECTION
 ******
 NEXT THREE METHODS ARE EMPTY SESSION DELEGATE METHODS
 WE IMPLEMENT THEM EMPTY JUST CUZ WE HAVE NO USE FOR THEM AS IS.
 WE IMPLEMENT didReceiveData BEC. DUH
 
******/

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// RECEIVED BYTE STREAM FROM REMOTE PEER
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
    
}

// STARTED RECEIVING RESOURCE FROM REMOTE PEER
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
    
}

// FINISHED RECEIVING A RESOURCE FROM REMOTE PEER
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
    
}
@end
