#import "ViewController.h"
#import <CoreRing/CoreRing.h>


@interface ViewController ()<CRApplicationDelegate>
@property (nonatomic, strong) CRApplication *ringApp;
@property (nonatomic, strong) NSDictionary *gestures;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController{
    int _counter;
    int width;
    int height;
    UIButton *_shootButton;
    UIView *StatusBar;
    UILabel *countLabel;
}

@synthesize PreviewLayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _counter = 0;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.ringApp) {
        [self startRing];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    width = self.view.bounds.size.width;
    height = self.view.bounds.size.height;
    
    //
    // Gestures
    //
    
    self.gestures = @{ @"circle" : CR_POINTS_CIRCLE,
                       @"left" : CR_POINTS_LEFT,
                       @"right" : CR_POINTS_RIGHT };
    
    [self StartCapture];
    
    
    _shootButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _shootButton.frame = CGRectMake(width * 0.5 - 40, height - 100 , 80, 80);
    
    NSArray *animationImageNames = [NSArray arrayWithObjects:@"tap.png", @"release.png", nil];
    NSMutableArray *animationImages = [NSMutableArray arrayWithCapacity:[animationImageNames count]];
    
    for (NSString *animationImageName in animationImageNames) {
        UIImage *image = [UIImage imageNamed:animationImageName];
        [animationImages addObject:image];
    }
    
    [_shootButton setImage:[animationImages objectAtIndex:0] forState:UIControlStateNormal];
    _shootButton.imageView.animationImages = animationImages;
    _shootButton.imageView.animationDuration = 2.0;
    [_shootButton.imageView startAnimating];
    
    [self.view addSubview:_shootButton];
    
    StatusBar = [[UIView alloc] init];
    StatusBar.frame = CGRectMake(0,-10,width,64);
    StatusBar.backgroundColor = [UIColor clearColor];
    StatusBar.alpha = 0.0;
    [self.view addSubview:StatusBar];
    
    countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,23,width,44)];
    countLabel.backgroundColor =  [UIColor clearColor];
    countLabel.textColor = [UIColor whiteColor];
    countLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.text = @"";
    [StatusBar addSubview:countLabel];
    
}

// サポートする画面の向き
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    WeAreRecording = NO;
}

-(void)StartCapture
{
    CaptureSession = [[AVCaptureSession alloc]init];
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(VideoDevice){
        NSError *error;
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error) {
            if ([CaptureSession canAddInput:VideoInputDevice]) {
                [CaptureSession addInput:VideoInputDevice];
            }else{
                NSLog(@"Couldn't add video input");
            }
        }
    }  else
    {
        NSLog(@"Couldn't create video capture device");
    }
    
    // 動画録画なのでAudioデバイスも取得する
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput)
    {
        // 同じように追加
        // 参考ではこんな感じになってたけど、厳密には上のVideoInputDeviceと同じようにやった方がいいと思う。
        [CaptureSession addInput:audioInput];
    }
    
    // PreviewLayerを設定する
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession]];
    
    PreviewLayer.orientation = AVCaptureVideoOrientationPortrait;
    // 引き伸ばし方とか設定。ここではアスペクト比が維持されるが、必要に応じてトリミングされる設定を適用
    [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    // ファイル用のOutputを作成
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    // 動画の長さ
    Float64 TotalSeconds = 60;
    // 一秒あたりのFrame数
    int32_t preferredTimeScale = 30;
    // 動画の最大長さ
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
    MovieFileOutput.maxRecordedDuration = maxDuration;
    // 動画が必要とする容量
    MovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;
    // sessionに追加
    if ([CaptureSession canAddOutput:MovieFileOutput])
        [CaptureSession addOutput:MovieFileOutput];
    
    // CameraDeviceの設定(後述)
    [self CameraSetOutputProperties];
    
    
    // 画像の質を設定。詳しくはドキュメントを読んでください
    [CaptureSession setSessionPreset:AVCaptureSessionPresetMedium];
    if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])     //Check size based configs are supported before setting them
        [CaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    
    // StoryBoard使えばこんなの要らない？
    CGRect layerRect = [[[self view] layer] bounds];
    [PreviewLayer setBounds:layerRect];
    [PreviewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
    
    // さっきLayerを設定したやつをaddSubviewして貼り付ける
    UIView *CameraView = [[UIView alloc] init];
    [[self view] addSubview:CameraView];
    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:PreviewLayer];
    
    
    // sessionをスタートさせる
    [CaptureSession startRunning];
    
}


- (void) CameraSetOutputProperties
{
    // ドキュメントには書いてなかったけど、このConnectionっていうのを貼らないとうまく動いてくれないっぽい
    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // Portraitに設定。これはあくまでもカメラ側からファイルへの出力。カメラーロールで再生した時にどの向きであって欲しいかを設定
    if ([CaptureConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
        [CaptureConnection setVideoOrientation:orientation];
    }
    
    //ここから下はお好みで
//    CMTimeShow(CaptureConnection.videoMinFrameDuration);
//    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
//    
//    if (CaptureConnection.supportsVideoMinFrameDuration)
//        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    if (CaptureConnection.supportsVideoMaxFrameDuration)
//        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    
//    CMTimeShow(CaptureConnection.videoMinFrameDuration);
//    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
}


// カメラ切り替えの時に必要
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == Position)
        {
            return Device;
        }
    }
    return nil;
}



// Camera切り替えアクション
- (void)CameraToggleButtonPressed
{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)        //Only do if device has multiple cameras
    {
        NSError *error;
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[VideoInputDevice device] position];
        // 今が通常カメラなら顔面カメラに
        if (position == AVCaptureDevicePositionBack)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        // 今が顔面カメラなら通常カメラに
        else if (position == AVCaptureDevicePositionFront)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (NewVideoInput != nil)
        {
            // beginConfiguration忘れずに！
            [CaptureSession beginConfiguration];            // 一度削除しないとダメっぽい
            [CaptureSession removeInput:VideoInputDevice];
            if ([CaptureSession canAddInput:NewVideoInput])
            {
                [CaptureSession addInput:NewVideoInput];
                VideoInputDevice = NewVideoInput;
            }
            else
            {
                [CaptureSession addInput:VideoInputDevice];
            }
            
            //Set the connection properties again
            [self CameraSetOutputProperties];
            
            
            [CaptureSession commitConfiguration];
        }
    }
}




- (void)StartStopButtonPressed
{
    
    if (!WeAreRecording)
    {
        [self startTimer];
        WeAreRecording = YES;
        
        //保存する先のパスを作成
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                //上書きは基本できないので、あったら削除しないとダメ
            }
        }
        //録画開始
        [MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
    }
    else
    {
        [self stopTimer];
        WeAreRecording = NO;
        
        [MovieFileOutput stopRecording];

    }
}



- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        //書き込んだのは/tmp以下なのでカメラーロールの下に書き出す
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
        {
            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                        completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 if (error)
                 {
                     
                 }
             }];
        }
        
    }
}


- (void)startRing {
    
    //
    // Create an instance
    //
    
    self.ringApp = [[CRApplication alloc] initWithDelegate:self background:NO];
    
    //
    // Install gestures if not installed.
    //
    
    if (![[_ringApp installedGestureIdentifiers] count]) {
        NSError *error;
        if (![_ringApp installGestures:_gestures error:&error]) {
            NSLog(@"%@", error);
            return;
        }
    }
    
    //
    // Set active gestures.
    //
    
    [self.ringApp setActiveGestureIdentifiers:_gestures.allKeys];
    
    //
    // Start a ring session.
    //
    
    [self.ringApp start];
}

- (void)endRing {
    self.ringApp = nil;
}

#pragma mark - CRApplicationDelegate

- (void)deviceDidDisconnect {
    NSLog(@"%s", __FUNCTION__);
}

- (void)deviceDidInitialize {
    NSLog(@"%s", __FUNCTION__);
}

- (void)didReceiveEvent:(CRRingEvent)event {
    NSLog(@"%s", __FUNCTION__);
    if (event == CRRingEventTap) {
        [self StartStopButtonPressed];
    }else if(event == CRRingEventLongPress){
        [self CameraToggleButtonPressed];
    }
}

- (void)didReceiveGesture:(NSString *)identifier {
    NSLog(@"%s %@", __FUNCTION__, identifier);
    
}

- (void)didReceiveQuaternion:(CRQuaternion)quaternion {
    NSLog(@"%s", __FUNCTION__);
}

- (void)didReceivePoint:(CGPoint)point {
    NSLog(@"%s", __FUNCTION__);
}


- (void)startTimer {

    if (![self.timer isValid]) {
        NSLog(@"startTimer");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            AudioServicesPlaySystemSound(1117);
            StatusBar.alpha = 1.0;
            StatusBar.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:0.4];
            countLabel.text = @"00:00";
            _counter = 0;
            
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                          target:self
                                                        selector:@selector(time:)
                                                        userInfo:nil
                                                         repeats:YES];
        }];
        
    }
}

- (void)stopTimer {
    if ([self.timer isValid]) {
        NSLog(@"stopTimer");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            AudioServicesPlaySystemSound(1118);
            countLabel.text = @"SAVE";
            StatusBar.alpha = 1.0;
            StatusBar.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:0.4];
            [self performBlock:^(void) {
                countLabel.text = @"";
                StatusBar.alpha = 0.0;
            }afterDelay:2];

            _counter = 0;
            [self.timer invalidate];
        }];
    }
}

-(void)time:(NSTimer*)timer{
    if ([self.timer isValid]) {
        _counter += 1;
        int m = (int)_counter / 60;
        int s = (int)_counter - (m * 60);
        
        NSString *lm;
        if (m < 10) {
            lm = [NSString stringWithFormat:@"0%d",m];
        }else{
            lm = [NSString stringWithFormat:@"%d",m];
        }
        
        NSString *ls;
        if (s < 10) {
            ls = [NSString stringWithFormat:@"0%d",s];
        }else{
            ls = [NSString stringWithFormat:@"%d",s];
        }
        
        countLabel.text = [NSString stringWithFormat:@"%@:%@",lm,ls];
    }
}


- (void)executeBlock__:(void (^)(void))block
{
    block();
}

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(executeBlock__:)
               withObject:[block copy]
               afterDelay:delay];
}

@end