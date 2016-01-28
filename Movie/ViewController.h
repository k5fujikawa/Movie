#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#import <AssetsLibrary/AssetsLibrary.h>
#define CAPTURE_FRAMES_PER_SECOND       20

@interface ViewController : UIViewController
<AVCaptureFileOutputRecordingDelegate>
{
    BOOL WeAreRecording;
    
    AVCaptureSession *CaptureSession;
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVCaptureDeviceInput *VideoInputDevice;
}

@property (retain) AVCaptureVideoPreviewLayer *PreviewLayer;

- (void) CameraSetOutputProperties;
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position;

// 録画を始めたり終えたりするイベント
- (void)StartStopButtonPressed;

// Back CameraとFront Cameraを切り替えるやつ
- (void)CameraToggleButtonPressed;

@end


