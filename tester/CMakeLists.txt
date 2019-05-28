#版本
cmake_minimum_required(VERSION 2.8) 
 
#项目名称                                      
project( test )  	
 
#设置OpenCV所在目录，为后面的find_package提供位置													  
#OpenCV_DIR为OpenCV源码编译后得到的文件夹(如上面的release目录)                 
set( OpenCV_DIR /Users/yifan/Downloads/opencv-4.0.1/build)
 
#会在OpenCV所在目录查找配置文件OpenCVConfig.cmake
find_package( OpenCV REQUIRED )  
 
#向工程添加源文件                                       
add_executable( test wrapper.cpp )  
 
#添加链接库                                 
target_link_libraries( test ${OpenCV_LIBS} )   
