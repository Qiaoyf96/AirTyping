//
//  OpenCVWrapper.h
//  TrueDepthStreamer
//
//  Created by kayo on 2019/4/19.
//  Copyright © 2019 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (NSString *)openCVVersionString;

+ (void) calcHistogramForPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                  bg:(CVImageBufferRef)background
                                  to:(CVPixelBufferRef)toBuffer;

@end

NS_ASSUME_NONNULL_END
