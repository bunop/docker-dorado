
# docker-dorado

This repository contains a Dockerfile for building a Docker image for
[dorado](https://github.com/nanoporetech/dorado) software with support for CUDA.
Built images are available on [Docker Hub](https://hub.docker.com/r/bunop/dorado).

## Available images

| Image name | CUDA version | Dorado version |
|------------|--------------|----------------|
| `bunop/dorado:v0.9.6-cuda11.8.0` | 11.8 | v0.9.6 |
| `bunop/dorado:v0.9.6-cuda12.8.0` | 12.8 | v0.9.6 |
| `bunop/dorado:v1.0.0-cuda11.8.0` | 11.8 | v1.0.0 |
| `bunop/dorado:v1.0.0-cuda12.8.0` | 12.8 | v1.0.0 |
| `bunop/dorado:latest` | 12.8 | v1.0.0 |

## Pull image from Docker Hub

get the latest image with:

```bash
docker pull bunop/dorado:latest
```

Or get a specific version with:

```bash
docker pull bunop/dorado:v0.9.6-cuda11.8.0
```

## Build image locally

Clone [this repository](https://github.com/bunop/docker-dorado) from GitHub:

```bash
git clone https://github.com/bunop/docker-dorado.git
```

Then enter into `docker-dorado` directory and build the image with:

```bash
docker build --build-arg BUILD_JOBS=4 \
    --build-arg CUDA_VERSION=11.8.0 \
    --build-arg DORADO_VERSION=v0.9.6 \
    -t bunop/dorado:v0.9.6-cuda11.8.0 .
```

Where `BUILD_JOBS` is the number of jobs to use for building the image,
`CUDA_VERSION` is the CUDA version to use and `DORADO_VERSION` is the
version of dorado to use. The default values are the *available number of cores*,
`11.8.0` and `v0.9.6` respectively.
