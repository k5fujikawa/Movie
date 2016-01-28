#import <UIKit/UIKit.h>
#import "CRCommon.h"

@protocol CRApplicationDelegate
- (void)deviceDidDisconnect;
- (void)deviceDidInitialize;
- (void)didReceiveEvent:(CRRingEvent)event;
- (void)didReceiveGesture:(NSString *)identifier;
- (void)didReceiveQuaternion:(CRQuaternion)quaternion;
- (void)didReceivePoint:(CGPoint)point;
@end


@interface CRApplication : NSObject

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate background:(BOOL)background;

- (BOOL)installGestures:(NSDictionary *)gestures error:(NSError **)error;
- (NSArray *)installedGestureIdentifiers;

- (void)setActiveGestureIdentifiers:(NSArray *)gestureIdentifiers;
- (NSArray *)activeGestureIdentifiers;

- (void)start;
- (void)setRingMode:(CRRingMode)ringMode;

@end
