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
#include <dlib/filtering.h>
#include <dlib/opencv.h>
#include "opencv2/opencv.hpp"
#include "opencv2/core/core.hpp"

using namespace cv;

@implementation DlibHelper {
    dlib::shape_predictor sp;
    
    
    int stateNum;
    int measureNum;
    KalmanFilter kf;
    Mat state;
    Mat processNoise;
    Mat measurement;
    
    bool flag;
    cv::Mat prevgray, gray;
    std::vector<cv::Point2f> prevTrackPts;
    std::vector<cv::Point2f> nextTrackPts;
    
    std::vector<dlib::point> predict_points;
    std::vector<dlib::point> kalman_points;
}

- (void)loadModel {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
    [self setup_kalman_filter];
    [self setup_optical_flow];
}

double cal_dist_diff(std::vector<cv::Point2f> curPoints, std::vector<cv::Point2f> lastPoints) {
    double variance = 0.0;
    double sum = 0.0;
    std::vector<double> diffs;
    if (curPoints.size() == lastPoints.size()) {
        for (int i = 0; i < curPoints.size(); i++) {
            double diff = std::sqrt(std::pow(curPoints[i].x - lastPoints[i].x, 2.0) + std::pow(curPoints[i].y - lastPoints[i].y, 2.0));
            sum += diff;
            diffs.push_back(diff);
        }
        double mean = sum / diffs.size();
        for (int i = 0; i < curPoints.size(); i++) {
            variance += std::pow(diffs[i] - mean, 2);
        }
        return variance / diffs.size();
    }
    return variance;
}

- (void)setup_kalman_filter {
    
    for (int i = 0; i < 68; i++) {
        predict_points.push_back(dlib::point(0, 0));
        kalman_points.push_back(dlib::point(0, 0));
    }
    stateNum = 272;
    measureNum = 136;
    
    kf = KalmanFilter(stateNum, measureNum, 0);
    
    state = Mat(stateNum, 1, CV_32FC1);
    processNoise = Mat(stateNum, 1, CV_32F);
    measurement = Mat::zeros(measureNum, 1, CV_32F);
    
    // Generate a matrix randomly
    randn(state, Scalar::all(0), Scalar::all(0.0));
    
    kf.transitionMatrix = Mat::zeros(stateNum, stateNum, CV_32F);
    for (int i = 0; i < 272; i++) {
        for (int j = 0; j < 272; j++) {
            if (i == j || (j - 136) == i) {
                kf.transitionMatrix.at<float>(i, j) = 1.0;
            } else {
                kf.transitionMatrix.at<float>(i, j) = 0.0;
            }
        }
    }
    
    //!< measurement matrix (H) Measurement Model
    setIdentity(kf.measurementMatrix);
    
    //!< process noise covariance matrix (Q)
    setIdentity(kf.processNoiseCov, Scalar::all(1e-5));
    
    //!< measurement noise covariance matrix (R)
    setIdentity(kf.measurementNoiseCov, Scalar::all(1e-1));
    
    //!< priori error estimate covariance matrix (P'(k)): P'(k)=A*P(k-1)*At + Q)*/  A代表F: transitionMatrix
    setIdentity(kf.errorCovPost, Scalar::all(1));
    
    randn(kf.statePost, Scalar::all(0), Scalar::all(0.1));
}

- (void)setup_optical_flow {

    for (int i = 0; i < 68; i++) {
        prevTrackPts.push_back(cv::Point2f(0, 0));
    }
}

- (NSArray<NSArray<NSValue *> *> *)detect: (CMSampleBufferRef)sampleBuffer
                        inside: (NSArray<NSValue *> *)rects {
    
    dlib::array2d<dlib::bgr_pixel> img;
    Mat image;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    size_t size = CVPixelBufferGetDataSize(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t width = size / height / 4;
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    image = Mat(int(height), int(width), CV_8UC3, baseBuffer, 0);
    
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
        
        // 1. detect shape
        CGRect rect = [rectValue CGRectValue];
        dlib::rectangle dlibRect((long)(rect.origin.x),
                                 (long)(rect.origin.y),
                                 (long)(rect.origin.x + rect.size.width),
                                 (long)(rect.origin.y + rect.size.height));
        dlib::full_object_detection shape = sp(img, dlibRect);
        
        Mat prediction = kf.predict();
        
        // 2. optical flow
        if (!flag) {
            cvtColor(image, prevgray, CV_BGR2GRAY);
            for (int i = 0; i < shape.num_parts(); i++) {
                prevTrackPts[i].x = shape.part(i).x();
                prevTrackPts[i].y = shape.part(i).y();
            }
            flag = true;
        }
        
        for (int i = 0; i<shape.num_parts(); i++) {
            dlib::point dlibPoint = shape.part(i);

            kalman_points[i].x() = dlibPoint.x();
            kalman_points[i].y() = dlibPoint.y();
        }
        
        for (int i = 0; i < 68; i++) {
            predict_points[i].x() = prediction.at<float>(i * 2);
            predict_points[i].y() = prediction.at<float>(i * 2 + 1);
        }
        
        cvtColor(image, gray, CV_BGR2GRAY);
        if (prevgray.data) {
            std::vector<uchar> status;
            std::vector<float> err;
            calcOpticalFlowPyrLK(prevgray, gray, prevTrackPts, nextTrackPts, status, err);
            std::cout << "variance:" <<cal_dist_diff(prevTrackPts, nextTrackPts) << std::endl;

            NSMutableArray<NSValue *> *landmarksOfOneFace = [NSMutableArray array];
            
            double diff = cal_dist_diff(prevTrackPts, nextTrackPts);
            
            if (diff > 1.0) { // the threshold value here depends on the system, camera specs, etc
                // if the face is moving so fast, use dlib to detect the face
                std::cout<< "DLIB" << std::endl;
                for (int i = 0; i < shape.num_parts(); i++) {
                    dlib::point dlibPoint = shape.part(i);
                    CGPoint cgPoint = CGPointMake(CGFloat(dlibPoint.x()), CGFloat(dlibPoint.y()));
                    NSValue *val = [NSValue valueWithCGPoint: cgPoint];
                    [landmarksOfOneFace addObject: val];
                }
            } else if (diff <= 1.0 && diff > 0.005) {
                // In this case, use Optical Flow
                std::cout<< "Optical Flow" << std::endl;
                for (int i = 0; i < nextTrackPts.size(); i++) {
                    Point2f dlibPoint = nextTrackPts[i];
                    CGPoint cgPoint = CGPointMake(CGFloat(dlibPoint.x), CGFloat(dlibPoint.y));
                    NSValue *val = [NSValue valueWithCGPoint: cgPoint];
                    [landmarksOfOneFace addObject: val];
                }
            } else {
                // In this case, use Kalman Filter
                std::cout<< "Kalman Filter" << std::endl;
                for (int i = 0; i < predict_points.size(); i++) {
                    dlib::point dlibPoint = predict_points[i];
                    CGPoint cgPoint = CGPointMake(CGFloat(dlibPoint.x()), CGFloat(dlibPoint.y()));
                    NSValue *val = [NSValue valueWithCGPoint: cgPoint];
                    [landmarksOfOneFace addObject: val];
                    nextTrackPts[i].x = predict_points[i].x();
                    nextTrackPts[i].y = predict_points[i].y();
                }
            }
            
            [landmarks addObject: landmarksOfOneFace.copy];
        }

        // previous points should be updated with the current points
        std::swap(prevTrackPts, nextTrackPts);
        std::swap(prevgray, gray);

        // Update Measurement
        for (int i = 0; i < 136; i++) {
            if (i % 2 == 0) {
                measurement.at<float>(i) = (float)kalman_points[i / 2].x();
            } else {
                measurement.at<float>(i) = (float)kalman_points[(i - 1) / 2].y();
            }
        }

        measurement += kf.measurementMatrix * state;

        // Correct Measurement
        kf.correct(measurement);
        
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
