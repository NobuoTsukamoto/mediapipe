#!/bin/sh

set -e
set -v

echo 'Please run this from root level mediapipe directory! \n Ex:'
echo '  sh mediapipe/examples/jetson_edgetpu/setup.sh  '

sleep 3

mkdir opencv_arm64_libs

cp mediapipe/examples/jetson_edgetpu/update_sources.sh update_sources.sh
chmod +x update_sources.sh

mv Dockerfile Dockerfile.orig
cp mediapipe/examples/jetson_edgetpu/Dockerfile Dockerfile

cp WORKSPACE WORKSPACE.orig
cp mediapipe/examples/jetson_edgetpu/WORKSPACE WORKSPACE

