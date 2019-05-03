//
//  OpenCVWrapper.m
//  TrueDepthStreamer
//
//  Created by kayo on 2019/4/19.
//  Copyright © 2019 Apple. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.hpp"


#define DEPTH_THRESH 3
#define VECTOR_THRESH 10
#define JUMP_THRESH 15


using namespace std;


@implementation OpenCVWrapper

vector<cv::Point3f> fin;


+ (NSString *)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

- (void)isThisWorking {
    cout << "hello world" << endl;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

void floodfill(cv::Mat &mat, int j, int i) {
    //    printf("%d %d\n", j, i);
    mat.at<uchar>(j, i) = 0;
    if (i > 0 && mat.at<uchar>(j, i - 1) != 0)
        floodfill(mat, j, i - 1);
    if (j > 0 && mat.at<uchar>(j - 1, i) != 0)
        floodfill(mat, j - 1, i);
    if (mat.at<uchar>(j, i + 1) != 0)
        floodfill(mat, j, i + 1);
}

float calc_depth(std::vector<int>&vec) {
    int sum = 0, length = int(vec.size());
    std::sort(vec.begin(),  vec.end());
    for (int i = 0; i < DEPTH_THRESH; i++) {
        sum += vec[i];
    }
    return sum / (float)DEPTH_THRESH;
}

bool nearcheck(cv::Mat &mat, int j, int i, int lo, int hi) {
    int window = 8;
    for (int jj = j - window; jj < j + window; jj++)
        for (int ii = i - window; ii < i + window; ii++)
            if (mat.at<uchar>(jj, ii) < lo || mat.at<uchar>(jj, ii) > hi) {
                return false;
            }
    return true;
}

bool x_axis_compare ( cv::Point3f a, cv::Point3f b) {
    if (a.x < b.x) return true;
    else return false;
}

float calc_distance (cv::Point3f a, cv::Point3f b) {
    return (a.x-b.x)*(a.x-b.x) + (a.z-b.z)*(a.z-b.z);
}

+ (void) calcHistogramForPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                  bg:(CVImageBufferRef)background
                                  to:(CVPixelBufferRef)toBuffer
{
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    
    cv::Mat canvas;
    canvas.create(height, width, CV_8UC4);
    
    
    cv::Mat mat(height, width, CV_16FC1, baseaddress, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CVPixelBufferLockBaseAddress(background, 0);
    void *baseaddress_bg = CVPixelBufferGetBaseAddressOfPlane(background, 0);
    
    CGFloat width_bg = CVPixelBufferGetWidth(background);
    CGFloat height_bg = CVPixelBufferGetHeight(background);
    
    cv::Mat bg_mat(height, width, CV_8UC4, baseaddress_bg, 0);
    CVPixelBufferUnlockBaseAddress(background, 0);
    
    
    mat *= 100;
    mat.convertTo(mat, CV_8UC1);
    
    cv::Mat mask;
    mask.create(height, width, CV_8UC4);
    cv::inRange(mat, 15, 40, mask);
    
    cv::bitwise_and(mat, mask, mat);
    //
    mat = (mat - 15) * (255 / (40-15.0));
    //    mat *= (255/40.0);
    
    
    
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(mat, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
    //RETR_EXTERNAL
    
    //    cv::cvtColor(mat, mat, cv::COLOR_GRAY2BGRA);
    
    int size = contours.size();
    // printf("%d\n", size);
    //    cv::Scalar colorContour = cv::Scalar( 255, 0, 0 );
    //    cv::Scalar colorHull = cv::Scalar( 0, 255, 0 );
    
    std::vector<cv::Point> fingers;
    std::vector<cv::Point3f> fingers3D;
    
    cv::Mat mat_copy = mat.clone();
    
    if (size != 0) {
        
        int largestContour = 0;
        int secondLargestContour = 1;
        
        std::vector<double> contourArea;
        
        for (int i = 0; i < size; i++)
            contourArea.push_back(cv::contourArea(contours[i]));
        
        for (int i = 1; i < size; i++)
        {
            if (contourArea[i] > contourArea[largestContour]) {
                secondLargestContour = largestContour;
                largestContour = i;
            } else if (contourArea[i] > contourArea[secondLargestContour]) {
                secondLargestContour = i;
            }
        }
        
        int inds[] = {largestContour, secondLargestContour};
        
        // printf("%d %d\n", largestContour, secondLargestContour);
        // printf("%lf %lf\n", contourArea[largestContour], contourArea[secondLargestContour]);
        
        for (int ind = 0; ind < 2; ind++) {
            if (ind == 1 && inds[1] == inds[0])
                break;
            if (inds[ind] >= contours.size())
                continue;
            if (contourArea[inds[ind]] < 5000)
                continue;
            cv::Rect boundingBox = cv::boundingRect(contours[inds[ind]]);
            cv::Point tl = boundingBox.tl();
            cv::Point br = boundingBox.br();
            int minDepth = 255;
            for (int i = tl.x; i < br.x; i++)
                for (int j = tl.y; j < br.y; j++) {
                    
                    
                    
                    uchar val = mat_copy.at<uchar>(j, i);
                    if (val < minDepth && val > 0)
                        minDepth = mat_copy.at<uchar>(j, i);
                }
            // printf("minDepth: %d\n", minDepth);
            
            for (int i = tl.x; i < br.x; i++)
                for (int j = tl.y; j < br.y; j++) {
                    if (mat_copy.at<uchar>(j, i) > minDepth + 30 || mat_copy.at<uchar>(j, i) == 0) {
                        bg_mat.at<cv::Vec4b>(j, i) = cv::Vec4b(0, 0, 0, 255);
                        mat_copy.at<uchar>(j, i) = 0;
                    }
                }
            
            // printf("%d %d %d %d\n", tl.x, tl.y, br.x, br.y);
            
            std::vector<int> color_total_sum;
            
            for (int i = tl.x; i < br.x; i++) {
                int color_sum[3] = {0, 0, 0};
                int sum = 0;
                for (int j = int(0.8 * tl.y + 0.2 * br.y); j < int(0.2 * tl.y + 0.8 * br.y); j++) {
                    cv::Vec4b color = bg_mat.at<cv::Vec4b>(j, i);
                    for (int k = 0; k < 3; k++) {
                        color_sum[k] += color[k];
                        sum += color[k];
                    }
                }
                for (int offset = 0; offset < 10; offset++)
                    for (int k = 0; k < 3; k++) {
                        cv::Vec4b color = cv::Vec4b(0, 0, 0, 255);
                        color[k] = 255;
                        bg_mat.at<cv::Vec4b>(int(tl.y + (color_sum[k] / 20000.0) * (br.y - tl.y) + offset), i) = color;
                        //                    printf("sumk %d", color_sum[k]);
                    }
                color_total_sum.push_back(sum);
            }
            
            int color_length = color_total_sum.size();
            int WINDOW = 20;
            std::vector<int> smooth_color_total_sum;
            for (int i = 0; i < color_length; i++) {
                int num = 0;
                int sum = 0;
                for (int j = MAX(i - WINDOW, 0); j < MIN(i + WINDOW, color_length); j++) {
                    sum += color_total_sum[j];
                    num += 1;
                }
                smooth_color_total_sum.push_back(sum / num);
            }
            
            
            
            for (int size = 0; size < 4; size++) {
                // printf("size %d\n", size);
                int lowest_j = 0;
                int lowest_i = 0;
                bool f = false;
                
                for (int j = br.y - 1; j >= tl.y; j--) {
                    for (int i = tl.x; i < br.x; i++)
                        if (mat_copy.at<uchar>(j, i) != 0 && color_total_sum[i] >= smooth_color_total_sum[i]) {
                            lowest_j = j;
                            lowest_i = i;
                            f = true;
                            break;
                        }
                    if (f) break;
                }
                if (!f) continue;
                
                floodfill(mat_copy, lowest_j, lowest_i);
                std::vector<int> vec;
                for (int i = 0; i < VECTOR_THRESH; i++)
                    vec.push_back(mat.at<uchar>(lowest_j - i, lowest_i));
                
                fingers.push_back(cv::Point(lowest_i, lowest_j));
                fingers3D.push_back(cv::Point3f(lowest_i, lowest_j, calc_depth(vec)));
            }
            
            int lowest_j = 0;
            int lowest_i = 0;
            bool f = false;
            
            for (int j = br.y - 1; j >= tl.y; j--) {
                for (int i = tl.x; i < br.x; i++)
                    if (mat.at<uchar>(j, i) > minDepth + 30 && mat.at<uchar>(j, i) < minDepth + 100 && color_total_sum[i] >= smooth_color_total_sum[i]) {
                        if (!nearcheck(mat, j, i, minDepth + 30, minDepth + 100)) continue;
                        lowest_j = j;
                        lowest_i = i;
                        f = true;
                        break;
                    }
                if (f) break;
            }
            if (!f) continue;
            
            std::vector<int> vec;
            for (int i = 0; i < VECTOR_THRESH; i++)
                vec.push_back(mat.at<uchar>(lowest_j - i, lowest_i));
            
            fingers.push_back(cv::Point(lowest_i, lowest_j));
            fingers3D.push_back(cv::Point3f(lowest_i, lowest_j, calc_depth(vec)));
        }
    }
    
    
    
    
    // sort(fingers3D.begin(), fingers3D.end(), x_axis_compare);
    
    
    // Smoothing:
    // if too near, erase one.
    for (int i = 0; i < fingers3D.size(); i++) {
        for (int j = i + 1; j < fingers3D.size(); j++) {
            if (abs(fingers3D[i].x - fingers3D[j].x) < 20) {
                fingers3D.erase(fingers3D.begin() + j);
                j--;
            }
        }
    }
    
    if (fingers3D.size() > fin.size()) {
        fin = fingers3D;
    }
    else if (fingers3D.size() < fin.size()) {
        fingers3D = fin;
    }
    else {
        for (int i = 0; i < fin.size(); i++) {
            if (calc_distance(fin[i], fingers3D[i]) > 400) {
                fingers3D[i] = fin[i];
            }
//            if (abs(fin[i].x - fingers3D[i].x) > JUMP_THRESH) {
//                fingers3D[i] = fin[i];
//            } else if (abs(fin[i].z - fingers3D[i].z) > JUMP_THRESH) {
//                fingers3D[i] = fin[i];
//            }
        }
        
        // if too near erase again
        bool erased = false;
        for (int i = 0; i < fingers3D.size(); i++) {
            for (int j = i + 1; j < fingers3D.size(); j++) {
                if (abs(fingers3D[i].x - fingers3D[j].x) < 20) {
                    fingers3D.erase(fingers3D.begin() + j);
                    j--;
                    erased = true;
                }
            }
        }
//        if (erased) {
//            fingers3D = fin;
//        } else {
//            fin = fingers3D;
//        }
        fin = fingers3D;
    }
    
    // sort(fingers3D.begin(), fingers3D.end(), x_axis_compare);
    
    for (int i = 1; i < fingers3D.size(); i++) {
//        if (fingers3D[i].x < fingers3D[i-1].x) {
//            cout << "not x_aligned" << endl;
//        }
        // cout << fingers3D[i].x << endl;
    }
    // cout << "a loop ends" << endl;
    
    
    
    
    cv::cvtColor(mat, mat, cv::COLOR_GRAY2BGRA);
    
    for (size_t i = 0; i < fingers.size(); i++) {
        if (i == fingers.size() - 1)
            cv::circle(mat, fingers[i], 9, cv::Scalar(0, 0, 255), 2);
        else
            cv::circle(mat, fingers[i], 9, cv::Scalar(0, 255, 0), 2);
    }
    
    cv::resize(mat, mat, cv::Size(mat.cols / 2, mat.rows / 2));
    
    cv::resize(bg_mat, bg_mat, cv::Size(bg_mat.cols / 2, bg_mat.rows / 2));
    
    cv::Mat ROI = canvas(cv::Range(mat.rows / 2, mat.rows / 2 + mat.rows), cv::Range(0, mat.cols));
    
    mat.copyTo(ROI);
    //    mat.copyTo(canvas);
    
    ROI = canvas(cv::Range(mat.rows / 2, mat.rows / 2 + mat.rows), cv::Range(mat.cols, mat.cols*2));
    cv::rectangle(ROI, cv::Point(0, 0), cv::Point(mat.cols, mat.rows), cv::Scalar(255, 255, 255), cv::FILLED);
    
    
    
    
    int fingersize = fingers3D.size();
    for (int i = 0; i < fingersize; i++) {
        cv::circle(ROI, cv::Point(fingers3D[i].x / 2, fingers3D[i].z * mat.rows / 255), 9, cv::Scalar(0, 0, 255), 2);
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             // [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             // [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             [NSNumber numberWithInt:width], kCVPixelBufferWidthKey,
                             [NSNumber numberWithInt:height], kCVPixelBufferHeightKey,
                             nil];
    
    CVPixelBufferLockBaseAddress(toBuffer, 0);
    void *base = CVPixelBufferGetBaseAddress(toBuffer) ;
    memcpy(base, canvas.data, canvas.total()*4);
    CVPixelBufferUnlockBaseAddress(toBuffer, 0);
    
    
    
    
    
}

@end
