#
# VERSION 0.2.1
# DOCKER-VERSION  28.1.1
# AUTHOR:         Paolo Cozzi <paolo.cozzi@ibba.cnr.it>
# DESCRIPTION:    A docker image with dorado installed
# TO_BUILD:       docker build --rm --build-arg BUILD_JOBS=4 -t bunop/dorado .
# TO_RUN:         docker run --rm --gpus all -ti bunop/dorado bash
# TO_TAG:         docker tag bunop/dorado:latest bunop/dorado:v0.9.6-cuda11.8.0
#

# This is an attempt to dockerize dorado as described in:
# https://github.com/nanoporetech/dorado/blob/release-v0.9/DEV.md

# This Dockerfile is based on the official NVIDIA CUDA image
# https://hub.docker.com/r/nvidia/cuda
ARG CUDA_VERSION=11.8.0
ARG DORADO_VERSION=v0.9.6

# start from the nvidia/cuda base image
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu22.04 AS build

# IMPORTANT!: without this redefinition, you can't use variables defined
# before the first FROM statement
ARG CUDA_VERSION
ARG DORADO_VERSION

# some metadata
LABEL maintainer="paolo.cozzi@ibba.cnr.it"
LABEL cuda.version="${CUDA_VERSION}"
LABEL dorado.version="${DORADO_VERSION}"
LABEL description="A docker image with dorado installed"

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
    git checkout ${DORADO_VERSION}

WORKDIR /root/dorado

# determining the number of jobs to use for building
ARG BUILD_JOBS
ENV BUILD_JOBS=${BUILD_JOBS:-$(nproc)}

# Creating the build directory
RUN . /root/venv/bin/activate && \
    cmake -S . -B cmake-build && \
    cmake --build cmake-build --config Release -j${BUILD_JOBS} && \
    cmake --install cmake-build --prefix /opt/dorado

# 2nd stage build
###############################################################################

FROM nvidia/cuda:${CUDA_VERSION}-base-ubuntu22.04

# IMPORTANT!: without this redefinition, you can't use variables defined
# before the first FROM statement
ARG CUDA_VERSION
ARG DORADO_VERSION

# some metadata
LABEL maintainer="paolo.cozzi@ibba.cnr.it"
LABEL cuda.version="${CUDA_VERSION}"
LABEL dorado.version="${DORADO_VERSION}"
LABEL description="A docker image with dorado installed"

# Set environment variable to disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# copy the application from build stage
COPY --from=build /opt/dorado /opt/dorado

# link dorado to /usr/local/bin
RUN ln -s /opt/dorado/bin/dorado /usr/local/bin/dorado

# install Miniforge
ENV MAMBA_DOCKERFILE_ACTIVATE=1
RUN apt-get update && apt-get install -y --no-install-recommends wget bzip2 && \
    wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
    echo "conda activate base" >> /etc/bash.bashrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/conda/bin:$PATH"

# copy the environment.yml file
COPY environment.yml /tmp/environment.yml

# crea l'environment conda (ad esempio chiamato "dorado-env")
RUN conda env create -f /tmp/environment.yml && \
    conda clean -afy

# imposta l'environment come default all'avvio
SHELL ["bash", "-c"]
ENV CONDA_DEFAULT_ENV=dorado-env
ENV PATH="/opt/conda/envs/dorado-env/bin:$PATH"
RUN echo "conda activate dorado-env" >> /etc/bash.bashrc

# setting default command
CMD ["dorado", "--help"]
