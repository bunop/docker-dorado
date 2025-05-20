# Usa immagine base ufficiale CUDA 11.5 con Ubuntu 20.04
FROM nvidia/cuda:11.5.2-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# Installazione dipendenze di sistema base
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    python3 \
    python3-pip \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Aggiorna pip e installa dipendenze python (modifica in base a requirements dorado)
RUN python3 -m pip install --upgrade pip setuptools wheel

# Clona dorado (scegli branch/tag se vuoi), e prepara build
RUN git clone https://github.com/nanoporetech/dorado.git /opt/dorado

WORKDIR /opt/dorado

# Crea cartella build, configura e compila
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda .. && \
    make -j$(nproc)

# (opzionale) aggiungi dorado path a PATH
ENV PATH="/opt/dorado/build/bin:${PATH}"

# Imposta entrypoint o command
CMD ["/bin/bash"]
