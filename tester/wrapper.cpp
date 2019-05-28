#include <opencv2/opencv.hpp>
#include <iostream>
#include <fstream>

// using namespace cv;

#define DEPTH_THRESH 3
#define VECTOR_THRESH 10
#define JUMP_THRESH 15

std::vector<cv::Point3f> fin;


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

std::vector<cv::Point3f> get_point(cv::Mat &mat, cv::Mat &bg_mat) { 

    imshow("bg", bg_mat);
    
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
                        minDepth = val;
                }
            printf("minDepth: %d\n", minDepth);
            
            for (int i = tl.x; i < br.x; i++)
                for (int j = tl.y; j < br.y; j++) {
                    if (mat_copy.at<uchar>(j, i) > minDepth + 30 || mat_copy.at<uchar>(j, i) == 0) {
                        bg_mat.at<cv::Vec4b>(j, i) = cv::Vec4b(0, 0, 0, 255);
                        mat_copy.at<uchar>(j, i) = 0;
                    }
                }
            
            // printf("%d %d %d %d\n", tl.x, tl.y, br.x, br.y);

            // imshow("mat_copy", mat_copy);
            
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
                        // bg_mat.at<cv::Vec4b>(int(tl.y + (color_sum[k] / 20000.0) * (br.y - tl.y) + offset), i) = color;
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
            
            
            
            for (int size = 0; size < 1; size++) {
                // printf("size %d\n", size);
                int lowest_j = 0;
                int lowest_i = 0;
                bool f = false;

                printf("%d %d\n", br.y, tl.y);
                
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
            
            // for (int j = br.y - 1; j >= tl.y; j--) {
            //     for (int i = tl.x; i < br.x; i++)
            //         if (mat.at<uchar>(j, i) > minDepth + 30 && mat.at<uchar>(j, i) < minDepth + 100 && color_total_sum[i] >= smooth_color_total_sum[i]) {
            //             if (!nearcheck(mat, j, i, minDepth + 30, minDepth + 100)) continue;
            //             lowest_j = j;
            //             lowest_i = i;
            //             f = true;
            //             break;
            //         }
            //     if (f) break;
            // }
            // if (!f) continue;
            
            // std::vector<int> vec;
            // for (int i = 0; i < VECTOR_THRESH; i++)
            //     vec.push_back(mat.at<uchar>(lowest_j - i, lowest_i));
            
            // fingers.push_back(cv::Point(lowest_i, lowest_j));
            // fingers3D.push_back(cv::Point3f(lowest_i, lowest_j, calc_depth(vec)));
        }
    }
    cv::cvtColor(mat, mat, cv::COLOR_GRAY2BGRA);
    
    
    
    // sort(fingers3D.begin(), fingers3D.end(), x_axis_compare);
    
    
    // // Smoothing:
    // // if too near, erase one.
    // for (int i = 0; i < fingers3D.size(); i++) {
    //     for (int j = i + 1; j < fingers3D.size(); j++) {
    //         if (abs(fingers3D[i].x - fingers3D[j].x) < 20) {
    //             fingers3D.erase(fingers3D.begin() + j);
    //             j--;
    //         }
    //     }
    // }
    
    // if (fingers3D.size() > fin.size()) {
    //     fin = fingers3D;
    // }
    // else if (fingers3D.size() < fin.size()) {
    //     fingers3D = fin;
    // }
    // else {
    //     for (int i = 0; i < fin.size(); i++) {
    //         if (calc_distance(fin[i], fingers3D[i]) > 400) {
    //             fingers3D[i] = fin[i];
    //         }
    //         // if (abs(fin[i].x - fingers3D[i].x) > JUMP_THRESH) {
    //         //     fingers3D[i] = fin[i];
    //         // } else if (abs(fin[i].z - fingers3D[i].z) > JUMP_THRESH) {
    //         //     fingers3D[i] = fin[i];
    //         // }
    //     }
        
    //     // if too near erase again
    //     bool erased = false;
    //     for (int i = 0; i < fingers3D.size(); i++) {
    //         for (int j = i + 1; j < fingers3D.size(); j++) {
    //             if (abs(fingers3D[i].x - fingers3D[j].x) < 20) {
    //                 fingers3D.erase(fingers3D.begin() + j);
    //                 j--;
    //                 erased = true;
    //             }
    //         }
    //     }
    //     // if (erased) {
    //     //     fingers3D = fin;
    //     // } else {
    //     //     fin = fingers3D;
    //     // }
    //     fin = fingers3D;
    // }


    for (size_t i = 0; i < fingers.size(); i++) {
        if (i == fingers.size() - 1)
            cv::circle(mat, cv::Point(fingers3D[i].x, fingers3D[i].y), 9, cv::Scalar(0, 0, 255), 2);
        else
            cv::circle(mat, cv::Point(fingers3D[i].x, fingers3D[i].y), 9, cv::Scalar(0, 255, 0), 2);
    }
    
    imshow("depth", mat);

    return fingers3D;
}

int main() {

    // std::streampos size;
    char * memblock;

    std::ifstream rgbfile("/Users/yifan/Downloads/rgb.bin", std::ios::in|std::ios::binary|std::ios::ate);
    std::ifstream depfile("/Users/yifan/Downloads/dep.bin", std::ios::in|std::ios::binary|std::ios::ate);
    
    size_t depfile_size = 307200;
    size_t rgbfile_size = depfile_size * 3 / 4;
    
    int tot_size = rgbfile.tellg() / rgbfile_size;
    printf("%d %d\n", tot_size, depfile.tellg() / depfile_size);

    if (rgbfile.is_open() && depfile.is_open()) {
        for (int i = 0; i < tot_size; i++) {
            cv::Mat rgb_mat(240, 320, CV_8UC3);
            cv::Mat depth_mat(480, 640, CV_8UC1);

            memblock = new char [rgbfile_size];
            rgbfile.seekg (rgbfile_size * i, std::ios::beg);
            rgbfile.read(memblock, rgbfile_size);
            std::memcpy(rgb_mat.data, memblock, rgb_mat.elemSize() * rgb_mat.total());
            delete[] memblock;

            memblock = new char [depfile_size];
            depfile.seekg (depfile_size * i, std::ios::beg);
            depfile.read(memblock, depfile_size);
            std::memcpy(depth_mat.data, memblock, depth_mat.elemSize() * depth_mat.total());
            delete[] memblock;

            cv::resize(rgb_mat, rgb_mat, cv::Size(640, 480));
            cv::cvtColor(rgb_mat, rgb_mat, cv::COLOR_BGR2BGRA);

            std::vector<cv::Point3f> fingers3D = get_point(depth_mat, rgb_mat);

            int fingersize = fingers3D.size();
            for (int i = 0; i < fingersize; i++) {
                printf("%f %f %f\n", fingers3D[i].x, fingers3D[i].y, fingers3D[i].z);
            }
            
            printf("==========\n");
            cv::waitKey(0);
        }

    }
    else printf("cannot open\n");

    // for (int i = 10; i < 1200; i++) {
    //     cv::Mat rgb_mat(480, 640, CV_8UC4);
    //     cv::Mat depth_mat(480, 640, CV_8UC1);

        
    //     if (rgbfile.is_open()) {
    //         size_t size = 1228800;
    //         // printf("rgbfile %d\n", (size_t)size);
    //         memblock = new char [size];
    //         rgbfile.seekg (0, std::ios::beg);
    //         rgbfile.read (memblock, size);
    //         rgbfile.close();
    //         std::memcpy(rgb_mat.data, memblock, rgb_mat.elemSize() * rgb_mat.total());
    //         delete[] memblock;
    //     }
    //     else printf("cannot open\n");

    //     // printf("%s", ("/Users/yifan/Downloads/log/rgb" + std::to_string(i) + ".bin").c_str());
    //     // imshow("rgb", rgb_mat);

    //     std::ifstream depfile(("/Users/yifan/Downloads/log/dep" + std::to_string(i) + ".bin").c_str(), std::ios::in|std::ios::binary|std::ios::ate);
    //     if (depfile.is_open()) {
    //         size_t size = 307200;
    //         memblock = new char [size];
    //         depfile.seekg (0, std::ios::beg);
    //         depfile.read (memblock, size);
    //         depfile.close();
    //         std::memcpy(depth_mat.data, memblock, depth_mat.elemSize() * depth_mat.total());
    //         delete[] memblock;
    //     }

    //     std::vector<cv::Point3f> fingers3D = get_point(depth_mat, rgb_mat);

    //     int fingersize = fingers3D.size();
    //     for (int i = 0; i < fingersize; i++) {
    //         printf("%f %f %f\n", fingers3D[i].x, fingers3D[i].y, fingers3D[i].z);
    //     }
        
    //     printf("==========\n");
    //     cv::waitKey(0);

    // }


    // cv::VideoCapture capture;
	// capture.open("VID2.mov");

    // double rate = capture.get(cv::CAP_PROP_FPS);
	// int delay = cvRound(rate);

    // if (!capture.isOpened()) {
	// 	return -1;
	// }		
	// else {
    //     int times = 0;
	// 	while (true) {
	// 		cv::Mat frame;
	// 		capture >> frame;
    //         times++;
    //         if (times < 60) continue;
	// 		if (frame.empty()) break;
	// 		imshow("处理前视频", frame);

    //         cv::Mat depth = frame(cv::Range(381, 972), cv::Range(443, 886));
    //         cv::Mat rgb = frame(cv::Range(972, 1563), cv::Range(443, 886));

    //         cv::cvtColor(depth, depth, cv::COLOR_BGR2GRAY);

    //         std::vector<cv::Point3f> fingers3D = get_point(depth, rgb);

    //         int fingersize = fingers3D.size();
    //         for (int i = 0; i < fingersize; i++) {
    //             printf("%f %f %f\n", fingers3D[i].x, fingers3D[i].y, fingers3D[i].z);
    //         }
    //         printf("==========\n");
	// 		cv::waitKey(0);
	// 	}
    // }

    // printf("%d\n", delay);
    return 0;
}
