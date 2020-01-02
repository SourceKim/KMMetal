////  UIImage+Dlib.cpp
//  KMMetal
//
//  Created by Su Jinjin on 2020/1/2.
//  Copyright © 2020 苏金劲. All rights reserved.
//

#include "UIImage+Dlib.h"

typedef unsigned char uchar;

void UIImageToDlibImage(const UIImage* uiImage, dlib::array2d<dlib::bgr_pixel> &dlibImage, bool alphaExist)
{
    CGFloat width = uiImage.size.width, height = uiImage.size.height;
    CGContextRef context;
    size_t pixelBits = CGImageGetBitsPerPixel(uiImage.CGImage);
    size_t pixelBytes = pixelBits/8;
    size_t dataSize = pixelBytes * ((size_t) width*height);
    uchar* imageData = (uchar*) malloc(dataSize);
    memset(imageData, 0, dataSize);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(uiImage.CGImage);
    
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    bool isGray = false;
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome) {
        // gray image
        bitmapInfo = kCGImageAlphaNone;
        isGray = true;
    }
    else
    {
        // color image
        if (!alphaExist) {
            bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
        }
    }
    
    context = CGBitmapContextCreate(imageData, (size_t) width, (size_t) height,
                                    8, pixelBytes*((size_t)width), colorSpace,
                                    bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), uiImage.CGImage);
    CGContextRelease(context);
    
    dlibImage.clear();
    dlibImage.set_size((long)height, (long)width);
    dlibImage.reset();
    long position = 0;
    while (dlibImage.move_next()){
        dlib::bgr_pixel& pixel = dlibImage.element();
        
        long offset = position*((long) pixelBytes);
        uchar b, g, r;
        if (isGray) {
            b = imageData[offset];
            g = imageData[offset];
            r = imageData[offset];
        } else {
            b = imageData[offset];
            g = imageData[offset+1];
            r = imageData[offset+2];
        }
        pixel = dlib::bgr_pixel(b, g, r);
        position++;
    }
    free(imageData);
}

UIImage* DlibImageToUIImage(dlib::array2d<dlib::bgr_pixel>& dlibImage)
{
    size_t height = (size_t) dlibImage.nr();
    size_t width = (size_t) dlibImage.nc();
    // no alpha
    uchar* imageData = (uchar *)malloc(height*width*3);
    dlibImage.reset();
    long position = 0;
    while (dlibImage.move_next())
    {
        dlib::bgr_pixel& pixel = dlibImage.element();
        
        long offset = position * 3;
        imageData[offset] = pixel.blue;
        imageData[offset+1] = pixel.green;
        imageData[offset+2] = pixel.red;
        position++;
    }
    
    NSData *data = [NSData dataWithBytes:imageData
                                  length:height*width*3];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef) data);
    CGBitmapInfo bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, 8, 24, 3*width, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    free(imageData);
    
    return finalImage;
}
