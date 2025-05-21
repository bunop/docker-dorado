#
# VERSION 0.1.0
# DOCKER-VERSION  28.1.1
# AUTHOR:         Paolo Cozzi <paolo.cozzi@ibba.cnr.it>
# DESCRIPTION:    A docker image with dorado installed
# TO_BUILD:       docker build --rm --build-arg BUILD_JOBS=4 -t bunop/dorado .
# TO_RUN:         docker run --rm --gpus all -ti bunop/dorado bash
# TO_TAG:         docker tag bunop/dorado:latest bunop/dorado:0.1.0
#

# This is an attempt to dockerize dorado as described in:
# https://github.com/nanoporetech/dorado/blob/release-v0.9/DEV.md

# start from the nvidia/cuda base image
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# MAINTAINER is deprecated. Use LABEL instead
LABEL maintainer="paolo.cozzi@ibba.cnr.it"

# Set environment variable to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install the required dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        ca-certificates \
        build-essential \
        libhdf5-dev \
        libssl-dev \
        autoconf \
        automake \
        python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

# install cmake using pip and venv
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install "cmake==3.25"

# Cloning dorado and choosing the v0.9.6 release
RUN git clone https://github.com/nanoporetech/dorado.git /root/dorado && \
    cd /root/dorado && \
    git checkout v0.9.6 && \
    git submodule update --init --recursive

WORKDIR /root/dorado

# determining the number of jobs to use for building
ARG BUILD_JOBS
ENV BUILD_JOBS=${BUILD_JOBS:-$(nproc)}

# Creating the build directory
RUN . /root/venv/bin/activate && \
    cmake -S . -B cmake-build && \
    cmake --build cmake-build --config Release -j${BUILD_JOBS} && \
    cmake --install cmake-build --prefix /opt/dorado

# setting default command
CMD ["/opt/dorado/bin/dorado", "--help"]
