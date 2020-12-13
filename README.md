# HawkEye - An automated Violence Detection System for CCTVs

With the increase of surveillance cameras in modern cities, there are insufficient human resource for monitoring all the screens at one time. In our project, we use machine learning techniques to detect violent behavior so a quick alarm can be given in time. 

We have built and implemented an automated system which can be integrated with the CCTV Systems and will alarm the appropriate authorities whenever violent behavior is detected in an CCTV footage. The detection is done with the assistance of an ML Model implemented in TFLite, for lightweight and fast execution. This Model was trained on [RWF2000 Dataset](https://github.com/mchengny/RWF2000-Video-Database-for-Violence-Detection) which is a collection of nearly 2000 vedio clips as a new data set for real-world violent behavior detection under surveillance camera.  

### There are two parts of of this project:

#### 1) The implementation of an example System code in Python (in the `SystemCode` directory) :- 

This directory contains an implementation of the Python Script which can be easily integrated with CCTV Systems. It is a multithreaded Python Script which uses OpenCV framework to captures frames from a video stream in one thread while simultaneously running the ML model in a different thread. This ensures smooth execution of multiple prediction by the ML model as well as efficient use of computing resources. Whenever this script detects violent behavior in a footage, it signals a central Firebase server which then forwards the location of camera along with a small footage clip to all the authorities connected with the organization.

#### 2) The implementation of the Flutter App (in the `Flutter App` directory) :-

This directory contains the implementation of an Flutter App 
