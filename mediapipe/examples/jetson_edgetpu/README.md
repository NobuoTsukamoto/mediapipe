# Jetson Nano + Edge TPU Setup (experimental)

**Dislaimer**: Running MediaPipe on Jetson Nano + Edge TPU is experimental, and this process may not be exact and is subject to change.

This file describes how to prepare a NVIDIA Jetson Nano and setup a linux Docker container for building MediaPipe applications that run on Edge TPU.

## Changes from the original ([Coral Dev Board Setup](https://github.com/google/mediapipe/tree/master/mediapipe/examples/coral))

* Run with NVIDIA Jetsn Nano + Google Coral Edge TPU USB Accelerator
* Object detection model is [SSDLite MobileNetEdgeTPU](https://github.com/tensorflow/models/blob/master/research/object_detection/g3doc/detection_model_zoo.md#pixel4-edge-tpu-models)

## HW requirements

* [NVIDIA Jetson Nano](https://developer.nvidia.com/embedded/jetson-nano-developer-kit)
* [Google Coral Edge TPU USB Accelerator](https://coral.ai/products/accelerator)
* [Raspberry Pi Camera Module v2](https://www.raspberrypi.org/products/camera-module-v2/)

## Jetson Nano Setup

* Flash your Jetson Nano with [JetPack](https://developer.nvidia.com/embedded/jetpack)  (JetPack 4.2.2 or higher).
* Connect Pi Camera to Jetson Nano.
* Software update.

        $ sudo apt update
        $ sudo apt upgrade
        $ sudo reboot

* Install the Edge TPU runtime ([see details](https://coral.withgoogle.com/docs/accelerator/get-started/#1-install-the-edge-tpu-runtime)).

        $ sudo apt install curl
        $ echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
        $ curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 
        $ sudo apt-get install libedgetpu1-std
        or
        $ sudo apt-get install libedgetpu1-max


## Before creating the Docker

* (on host machine) run _setup.sh_ from MediaPipe root directory

        $ sh mediapipe/examples/jetson_edgetpu/setup.sh

* (on Jetson Nano device) prepare MediaPipe

        $ cd ~
        $ sudo apt-get install git
        $ git clone <this repository>
        $ mkdir mediapipe/bazel-bin

* (on Jetson Nano device) find all opencv libs and copy lib files

        $ cd ~
        $ mkdir libopencv
        $ find /usr/lib/ -name 'libopencv*so' | xargs -i cp -p {} ./libopencv
        $ tar zcf libopencv.tar.gz libopencv
        $ cp libopencv.tar.gz /tmp/.


* (on host machine) Remote file copy opencv libs from Jetson Nano device to a local folder inside MediaPipe checkout:

        # in root level mediapipe folder #
        $ scp <jetson-user-name>@xxx.xxx.xxx.xxx(jetson-ip-address):/tmp/libopencv.tar.gz ./
        $ tar xf ./libopencv.tar.gz
        $ cp ./libopencv/libopencv_* ~/mediapipe/opencv_arm64_libs/
        $ rm -rf libopencv.tar.gz libopencv/

* (on host machine) Create and start the docker environment

        # from mediapipe root level directory #
        $ sudo docker build -t jetson_edgetpu .
        $ sudo docker run -it --name jetson_edgetpu jetson_edgetpu:latest

## Inside the Docker environment

* Update library paths in /mediapipe/third_party/opencv_linux.BUILD

  (replace 'x86_64-linux-gnu' with 'aarch64-linux-gnu')

        "lib/aarch64-linux-gnu/libopencv_core.so",
        "lib/aarch64-linux-gnu/libopencv_calib3d.so",
        "lib/aarch64-linux-gnu/libopencv_features2d.so",
        "lib/aarch64-linux-gnu/libopencv_highgui.so",
        "lib/aarch64-linux-gnu/libopencv_imgcodecs.so",
        "lib/aarch64-linux-gnu/libopencv_imgproc.so",
        "lib/aarch64-linux-gnu/libopencv_video.so",
        "lib/aarch64-linux-gnu/libopencv_videoio.so",

* Attempt to build hello world (to download external deps)

        # bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/examples/desktop/hello_world:hello_world

* Edit  /mediapipe/bazel-mediapipe/external/com_github_glog_glog/src/signalhandler.cc

      on line 78, replace

        return (void*)context->PC_FROM_UCONTEXT;

      with

        return NULL;

* Edit  /edgetpu/libedgetpu/BUILD

      to add this build target

         cc_library(
           name = "lib",
           srcs = [
               "libedgetpu.so",
           ],
           visibility = ["//visibility:public"],
         )

* Edit *tflite_inference_calculator.cc*  BUILD rules:

        # sed -i 's/\":tflite_inference_calculator_cc_proto\",/\":tflite_inference_calculator_cc_proto\",\n\t\"@edgetpu\/\/:header\",\n\t\"@libedgetpu\/\/:lib\",/g' mediapipe/calculators/tflite/BUILD

      The above command should add

        "@edgetpu//:header",
        "@libedgetpu//:lib",

      to the _deps_ of tflite_inference_calculator.cc

#### Now try cross-compiling for device

* Object detection demo

        # bazel build -c opt --crosstool_top=@crosstool//:toolchains --compiler=gcc --cpu=aarch64 --define MEDIAPIPE_DISABLE_GPU=1 --copt -DMEDIAPIPE_EDGE_TPU --copt=-flax-vector-conversions mediapipe/examples/jetson_edgetpu:object_detection_cpu

 Copy object_detection_cpu binary to the MediaPipe checkout on the Jetson Nano device

        # outside docker env, open new terminal on host machine #
        $ sudo docker ps
        $ sudo docker cp <container-id>:/mediapipe/bazel-bin/mediapipe/examples/jetson_edgetpu/object_detection_cpu /tmp/.
        $ scp /tmp/object_detection_cpu <jetson-user-name>@xxx.xxx.xxx.xxx(jetson-ip-address):/home/<jetson-user-name>/mediapipe/bazel-bin/.

* Face detection demo

        # bazel build -c opt --crosstool_top=@crosstool//:toolchains --compiler=gcc --cpu=aarch64 --define MEDIAPIPE_DISABLE_GPU=1 --copt -DMEDIAPIPE_EDGE_TPU --copt=-flax-vector-conversions mediapipe/examples/jetson_edgetpu:face_detection_cpu

 Copy face_detection_cpu binary to the MediaPipe checkout on the Jetson nano device

        # outside docker env, open new terminal on host machine #
        $ sudo docker ps
        $ sudo docker cp <container-id>:/mediapipe/bazel-bin/mediapipe/examples/jetson_edgetpu/face_detection_cpu /tmp/.
        $ scp /tmp/face_detection_cpu <jetson-user-name>@xxx.xxx.xxx.xxx(jetson-ip-address):/home/<jetson-user-name>/mediapipe/bazel-bin/.

## On the Jetson Nano device (with display)

     # Object detection
     $ cd ~/mediapipe
     $ chmod +x bazel-bin/object_detection_cpu
     $ export GLOG_logtostderr=1
     $ bazel-bin/object_detection_cpu --calculator_graph_config_file=mediapipe/examples/jetson_edgetpu/graphs/object_detection_desktop_live.pbtxt

     # Face detection
     $ cd ~/mediapipe
     $ chmod +x bazel-bin/face_detection_cpu
     $ export GLOG_logtostderr=1
     $ bazel-bin/face_detection_cpu --calculator_graph_config_file=mediapipe/examples/jetson_edgetpu/graphs/face_detection_desktop_live.pbtxt

