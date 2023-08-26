# nextcloud-multimedia

This is a fork that probably nobody should use since I don't really know what
I'm doing LOL.

The original fails to build, due to an update on cmake that no longer ignores
the --config flag, in addition to that I decided to update the base image to
nextcloud:latest and enable hardware acceleration through vapi.

More changes may come.

Dockerfile for building the latest Nextcloud apache image with additional
packages and libraries built in:

- ffmpeg
- pdlib
- bzip

This image will permit Nextcloud Memories to handle videos and install facial
recognition plugins.
