//
//  DlibHelper.m
//  KMMetal
//
//  Created by 苏金劲 on 2020/1/1.
//  Copyright © 2020 苏金劲. All rights reserved.
//

#import "DlibHelper.h"

#import "UIImage+Dlib.h"
#include <dlib/image_processing/frontal_face_detector.h>

@implementation DlibHelper {
    dlib::shape_predictor sp;
}

- (void)loadModel {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
}

- (NSArray<NSArray<NSValue *> *> *)detect: (CMSampleBufferRef)sampleBuffer
                        inside: (NSArray<NSValue *> *)rects {
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    size_t size = CVPixelBufferGetDataSize(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t width = size / height / 4;
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    img.set_size(height, width);
    
    // 1. Copy sample buffer
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();

        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];

        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;

        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // 2. Do landmarks detection
    NSMutableArray<NSArray<NSValue *> *> *landmarks = [NSMutableArray array];
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        dlib::rectangle dlibRect((long)(rect.origin.x),
                                 (long)(rect.origin.y),
                                 (long)(rect.origin.x + rect.size.width),
                                 (long)(rect.origin.y + rect.size.height));
        dlib::full_object_detection shape = sp(img, dlibRect);
        
        NSMutableArray<NSValue *> *landmarksOfOneFace = [NSMutableArray array];
        for (int i = 0; i<shape.num_parts(); i++) {
            dlib::point dlibPoint = shape.part(i);
            CGPoint cgPoint = CGPointMake(CGFloat(dlibPoint.x()), CGFloat(dlibPoint.y()));
            NSValue *val = [NSValue valueWithCGPoint: cgPoint];
            [landmarksOfOneFace addObject: val];
        }
        [landmarks addObject: landmarksOfOneFace.copy];
    }

    //3. Return
    return landmarks.copy;
}

- (NSArray<NSArray<NSValue *> *> *)detect: (UIImage *)uiImage {
    
    dlib::array2d<dlib::bgr_pixel> img;

    size_t height = uiImage.size.height;
    size_t width = uiImage.size.width;
    
    img.set_size(height, width);
    
    // 1. detector
    dlib::frontal_face_detector detector = dlib::get_frontal_face_detector();
    
    // 2. UIImage to Dlib-Image
    UIImageToDlibImage(uiImage, img, true);
    
    // 3. Detect rects in img
    std::vector<dlib::rectangle> rects = detector(img);
    
    // 4. Parse landmarks
    NSMutableArray<NSArray<NSValue *> *> *landmarks = [NSMutableArray array];
    
    for (int i=0; i<rects.size(); i++) {
        
        dlib::full_object_detection shape = sp(img, rects[i]);
        
        NSMutableArray<NSValue *> *landmarksOfOneFace = [NSMutableArray array];
        
        for (int i = 0; i<shape.num_parts(); i++) {
            dlib::point dlibPoint = shape.part(i);
            CGPoint cgPoint = CGPointMake(CGFloat(dlibPoint.x() - 8), CGFloat(dlibPoint.y()));
            NSValue *val = [NSValue valueWithCGPoint: cgPoint];
            [landmarksOfOneFace addObject: val];
//            draw_solid_circle(img, dlibPoint, 3, dlib::rgb_pixel(0, 255, 255));
        }
        [landmarks addObject: landmarksOfOneFace.copy];
    }

    // 5. Return
    return landmarks.copy;
}

@end
