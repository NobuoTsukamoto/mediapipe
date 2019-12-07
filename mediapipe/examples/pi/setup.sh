#!/bin/sh

set -e
set -v

echo 'Please run this from root level mediapipe directory! \n Ex:'
echo '  sh mediapipe/examples/pi/setup.sh  '

sleep 3

mkdir opencv_armv7l_libs

cp mediapipe/examples/pi/update_sources.sh update_sources.sh
chmod +x update_sources.sh

mv Dockerfile Dockerfile.orig
cp mediapipe/examples/pi/Dockerfile Dockerfile

cp WORKSPACE WORKSPACE.orig
cp mediapipe/examples/pi/WORKSPACE WORKSPACE

