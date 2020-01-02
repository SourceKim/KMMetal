////  UIImage+Dlib.hpp
//  KMMetal
//
//  Created by Su Jinjin on 2020/1/2.
//  Copyright © 2020 苏金劲. All rights reserved.
//

#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#import <UIKit/UIKit.h>

void UIImageToDlibImage(const UIImage* uiImage, dlib::array2d<dlib::bgr_pixel> &dlibImage, bool alphaExist);

UIImage* DlibImageToUIImage(dlib::array2d<dlib::bgr_pixel>& dlibImage);
