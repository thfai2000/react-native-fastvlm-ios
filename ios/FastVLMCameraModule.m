//
//  FastVLMCameraModule.m
//  FastVLMCamera
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(FastVLMCameraModule, NSObject)

RCT_EXTERN_METHOD(analyzeCameraData:(NSString *)prompt
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end