
#import "FastvlmIosSpec.h"
#import "FastvlmIos.h"

@implementation FastvlmIos

RCT_EXPORT_MODULE(FastvlmIos)

RCT_REMAP_METHOD(multiply, addA:(NSInteger)a
                      andB:(NSInteger)b
                withResolver:(RCTPromiseResolveBlock) resolve
                withRejecter:(RCTPromiseRejectBlock) reject)
{
    NSNumber *result = [[NSNumber alloc] initWithInteger: a * b ];
    resolve(result);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeFastvlmIosSpecJSI>(params);
}

@end