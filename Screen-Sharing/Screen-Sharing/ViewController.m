//
//  ViewController.m
//  Screen-Sharing
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import "ViewController.h"
#import "TBScreenCapture.h"
#import <OpenTok/OpenTok.h>
#import "SmoothLineView.h"


// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
static NSString* const kApiKey = @"45191772";
// Replace with your generated session ID
static NSString* const kSessionId = @"2_MX40NTE5MTc3Mn5-MTQyNzcxMjcwNjAzNX5nNzJEb1JNVTRtSmhVeTlBUVJ0aGFaQ2F-fg";
// Replace with your generated token
static NSString* const kToken = @"T1==cGFydG5lcl9pZD00NTE5MTc3MiZzaWc9YzcwNDA1ZWJlNjQxZTY3YTAzMTNhNGE1NjhhNmE3MmEyMjg2NmU5ZDpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTJfTVg0ME5URTVNVGMzTW41LU1UUXlOemN4TWpjd05qQXpOWDVuTnpKRWIxSk5WVFJ0U21oVmVUbEJVVkowYUdGYVEyRi1mZyZjcmVhdGVfdGltZT0xNDI3NzEyNzQ3Jm5vbmNlPTAuMTU3MTk1MDQ3Mjg1NjM5NSZleHBpcmVfdGltZT0xNDMwMzA0Njgw";

@interface ViewController () <OTSessionDelegate, OTPublisherDelegate, OTSubscriberDelegate>

@end

//static double widgetHeight = 240;
//static double widgetWidth = 320;
static bool subscribeToSelf = NO;

@implementation ViewController {
    OTSession* _session;
    OTPublisherKit* _publisher;
    OTSubscriber* _subscriber;
    dispatch_queue_t  _queue;
    dispatch_source_t _timer;
    CGPoint lastPoint;
    BOOL mouseSwiped;
    int mouseMoved;
    UIImageView *screenShareView;
     UIView *screenShareHeader;
    UIImageView *transperentView1;
    UIView *transperentView2;
    UIImage * resultImage;
    SmoothLineView *smoothView;
    
}
@synthesize timeDisplay;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
  /*  // Setup a timer to periodically update the UI. This gives us something
    // dynamic that we can see on the receiver's end to verify everything works.
    _queue = dispatch_queue_create("ticker-timer", 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0),
                              10ull * NSEC_PER_MSEC, 1ull * NSEC_PER_SEC);
    
    dispatch_source_set_event_handler(_timer, ^{
        double timestamp = [[NSDate date] timeIntervalSince1970];
        int64_t timeInMilisInt64 = (int64_t)(timestamp*1000);
        
       // NSString *mills = [NSString stringWithFormat:@"%lld", timeInMilisInt64];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
           // [self.timeDisplay setText:mills];
        });
    });
    
    dispatch_resume(_timer);
    */
    _session = [[OTSession alloc] initWithApiKey:kApiKey
                                       sessionId:kSessionId
                                    delegate:self];

    
    [self doConnect];
    UIImage * targetImage = [UIImage imageNamed:@"sample_1.png"];
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 0.f);
    [targetImage drawInRect:CGRectMake(0.f, 0.f, self.view.frame.size.width, self.view.frame.size.height)];
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:resultImage];
    
  
    
    
   // [self showScreenShareUI];
    
   // transperentView1 = [[UIImageView alloc] initWithFrame:self.view.frame];
   // transperentView1.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0];
   // transperentView1.image = resultImage;
   // [transperentView1 setOpaque:NO];
   // transperentView1.image = [UIImage imageNamed:@"shadowAlpha"];
   // [self.view addSubview:transperentView1];
    
    smoothView = [[SmoothLineView alloc] initWithFrame:self.view.frame];
  //  smoothView.backgroundColor = [UIColor colorWithPatternImage:resultImage];
  //  smoothView.backgroundColor = [UIColor grayColor];
   // smoothView.alpha = 0.5;
    [self.view addSubview:smoothView];
    
    
}
-(void)showScreenShareUI
{
    screenShareView = [[UIImageView alloc] initWithFrame:self.view.frame];
    screenShareView.image = [UIImage imageNamed:@"sample_1.png"];
    
    
    //callerVideo.frame = CGRectMake(25, 483, 83, 83);
    // callerVideo.backgroundColor = [UIColor whiteColor];
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(screenShareView.frame.size.width -65, 0, 75, 25);
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [screenShareHeader addSubview:closeButton];
    
    [self.view addSubview:screenShareView];
    [self.view addSubview:screenShareHeader];
    
    
    
    
    
    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - OpenTok methods

- (void)doConnect
{
    NSLog(@"connection called");
    OTError *error = nil;
    
    [_session connectWithToken:kToken error:&error];
    if (error) {
        [self showAlert:[error localizedDescription]];
    }
}
- (void)doPublish
{
    // Setup the publisher with customizations for screencasting. You might
    // consider setting this up as an OTPublisherKit subclass, but it's here
    // for brevity and consolidation.
    
    // We're not using Audio for this publisher, so don't bother setting up the
    // audio track.
    _publisher =
    [[OTPublisherKit alloc] initWithDelegate:self
                                        name:[UIDevice currentDevice].name
                                  audioTrack:YES
                                  videoTrack:YES];
    
    // Additionally, the publisher video type can be updated to signal to
    // receivers that the video is from a screencast. This value also disables
    // some downsample scaling that is used to adapt to changing network
    // conditions. We will send at a lower framerate to compensate for this.
  
    [_publisher setVideoType:OTPublisherKitVideoTypeScreen];
    
    // This disables the audio fallback feature when using routed sessions.
    _publisher.audioFallbackEnabled = NO;

    // Finally, wire up the video source.
    SmoothLineView *copyOfView =
    [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:smoothView]];
    
    copyOfView.backgroundColor = [UIColor colorWithPatternImage:resultImage];
    
  //  SmoothLineView *copy = [smoothView c]
    
    TBScreenCapture* videoCapture =
    [[TBScreenCapture alloc] initWithView:smoothView];
    [_publisher setVideoCapture:videoCapture];
    
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error) {
        [self showAlert:[error localizedDescription]];
    }
}

- (void)cleanupPublisher {
    _publisher = nil;
}

/**
 * Instantiates a subscriber for the given stream and asynchronously begins the
 * process to begin receiving A/V content for this stream. Unlike doPublish,
 * this method does not add the subscriber to the view hierarchy. Instead, we
 * add the subscriber only after it has connected and begins receiving data.
 */
- (void)doSubscribe:(OTStream*)stream
{
    _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
   // _subscriber.view.backgroundColor = [UIColor clearColor];
    
    OTError *error = nil;
    [_session subscribe:_subscriber error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}

/**
 * Cleans the subscriber from the view hierarchy, if any.
 * NB: You do *not* have to call unsubscribe in your controller in response to
 * a streamDestroyed event. Any subscribers (or the publisher) for a stream will
 * be automatically removed from the session during cleanup of the stream.
 */
- (void)cleanupSubscriber
{
    [_subscriber.view removeFromSuperview];
    _subscriber = nil;
}

# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)",
     session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
}


- (void)session:(OTSession*)mySession streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@)", stream.streamId);
    // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
    // have seen on the OpenTok session.
    if (nil == _subscriber && !subscribeToSelf)
    {
        [self doSubscribe:stream];
    }
}

- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
}

- (void) session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void) session:(OTSession *)session
connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    if ([_subscriber.stream.connection.connectionId
         isEqualToString:connection.connectionId])
    {
        [self cleanupSubscriber];
    }
}

- (void) session:(OTSession*)session didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    NSLog(@"subscriberDidConnectToStream (%@)",
          subscriber.stream.connection.connectionId);
    assert(_subscriber == subscriber);
    [_subscriber.view setFrame:self.view.frame];
    _subscriber.view.backgroundColor = [UIColor clearColor];
    _subscriber.view.alpha = 0.4;
    [self.view addSubview:_subscriber.view];
    
     [self.view bringSubviewToFront:smoothView];
}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@",
          subscriber.stream.streamId,
          error);
}

- (void)subscriberVideoDataReceived:(OTSubscriber*)subscriber
{
    //NSLog(@"subscriberVideoDataReceived");
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream
{
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
    // all participants in the OpenTok session. We will attempt to subscribe to
    // our own stream. Expect to see a slight delay in the subscriber video and
    // an echo of the audio coming from the device microphone.
    if (nil == _subscriber && subscribeToSelf)
    {
        [self doSubscribe:stream];
    }
}

- (void)showAlert:(NSString *)string
{
	dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OTError"
                                                        message:string
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] ;
        [alert show];
    });
}


/*

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    
    if ([touch tapCount] == 2) {
        transperentView1.image = [UIImage imageNamed:@"shadowAlpha"];
        return;
    }
    
    lastPoint = [touch locationInView:transperentView1];
    //lastPoint.y -= 20;
    //lastPoint.x -=20;
    
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    
    NSLog(@"touches moved..");
    mouseSwiped = YES;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:transperentView1];
    //currentPoint.y -= 20;
    //currentPoint.x -= 20;
    
    
    UIGraphicsBeginImageContext(transperentView1.frame.size);
    [transperentView1.image drawInRect:CGRectMake(0, 0, transperentView1.frame.size.width, transperentView1.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 4.0);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    transperentView1.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    lastPoint = currentPoint;
    
    mouseMoved++;
    
    if (mouseMoved == 10) {
        mouseMoved = 0;
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    
    if ([touch tapCount] == 2) {
        transperentView1.image = [UIImage imageNamed:@"shadowAlpha"];
        return;
    }
    
    
    if(!mouseSwiped) {
        UIGraphicsBeginImageContext(screenShareView.frame.size);
        [transperentView1.image drawInRect:CGRectMake(0, 0,transperentView1.frame.size.width,transperentView1.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 4.0);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        CGContextFlush(UIGraphicsGetCurrentContext());
        transperentView1.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}
 */
@end
