//
//  DlibHelper.h
//  KMMetal
//
//  Created by 苏金劲 on 2020/1/1.
//  Copyright © 2020 苏金劲. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface DlibHelper : NSObject

- (void)loadModel;

- (NSArray<NSArray<NSValue *> *> *)detect: (CMSampleBufferRef)sampleBuffer
                        inside: (NSArray<NSValue *> *)rects;

@end

NS_ASSUME_NONNULL_END
