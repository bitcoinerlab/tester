# -------------------------------------------------------
# Dockerfile for bitcoinerlab/tester
# -------------------------------------------------------

# Description:
# This Dockerfile sets up an environment based on a fork from:
# https://github.com/bitcoinjs/regtest-server/tree/master/docker
# 
# Main Changes:
# 1. Installation and execution of Blockstream's electrs server.
# 2. Esplora backend running on port 3002.
# 3. Electrum server running on port 60401.
# 4. Bitcoin Core set to v26.
# 5. Esplora web server.

# Quick Guide:
# 1. Building a Local Image:
#    $ docker build -t bitcoinerlab/tester .
#
# 2. Building for Multiple Platforms & Uploading to Docker Hub:
#    a. Login to Docker Hub:
#       $ docker login -u bitcoinerlab
#
#    b. Set up for multi-platform builds:
#       $ docker buildx create --use
#
#    c. Build & Push to Docker Hub:
#       $ docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t bitcoinerlab/tester . --push
#       Discard v7 if it the OS kills the compilation process for using too many resources
#       $ docker buildx build --platform linux/amd64,linux/arm64 -t bitcoinerlab/tester . --push
#
# 3. Running the Image:
#    $ docker run -d -p 8080:8080 -p 60401:60401 -p 3002:3002 bitcoinerlab/tester

# -------------------------------------------------------
# Credit for the original work goes to Jonathan Underwood.
# -------------------------------------------------------


FROM ubuntu:22.04
LABEL maintainer="José Luis Landabaso @bitcoinerlab"

ARG TARGETPLATFORM
RUN echo "TARGETPLATFORM: ${TARGETPLATFORM}"

RUN apt update && apt install -y software-properties-common

RUN apt update && \
   apt install -y \
   curl \
   wget \
   tar \
   python3 \
   python3-pip \
   build-essential \
   gnupg2 \
   libzmq3-dev \
   libsnappy-dev && \
   curl --silent --location https://deb.nodesource.com/setup_20.x | bash -


WORKDIR /root

RUN wget "https://bitcoincore.org/bin/bitcoin-core-26.0/SHA256SUMS" && \
    wget "https://bitcoincore.org/bin/bitcoin-core-26.0/SHA256SUMS.asc"

RUN ARCH="unsupported"; \
  case "$TARGETPLATFORM" in \
  "linux/amd64") ARCH="x86_64-linux-gnu" ;; \
  "linux/arm64") ARCH="aarch64-linux-gnu" ;; \
  "linux/arm/v7") ARCH="arm-linux-gnueabihf" ;; \
  *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
  esac && \
  wget "https://bitcoincore.org/bin/bitcoin-core-26.0/bitcoin-26.0-${ARCH}.tar.gz" && \
  sha256sum --ignore-missing --check SHA256SUMS && \
  tar xvf "bitcoin-26.0-${ARCH}.tar.gz" && \
  rm -f "bitcoin-26.0-${ARCH}.tar.gz" SHA256SUM* && \
  cp -R bitcoin-26.0/* /usr/ && \
  rm -rf bitcoin-26.0/

RUN apt install -y \
  git \
  vim \
  nodejs && \
  mkdir /root/regtest-data && \
  echo "satoshi" > /root/regtest-data/KEYS

COPY run.sh run_bitcoind_service.sh install_leveldb.sh ./

RUN chmod +x install_leveldb.sh && \
  chmod +x run_bitcoind_service.sh && \
  chmod +x run.sh && \
  ./install_leveldb.sh

RUN git clone -b fix-bitcoinjs-lib-version https://github.com/bitcoinerlab/regtest-server.git

WORKDIR /root/regtest-server

# Change the checkout branch if you need to. Must fetch because of Docker cache
# RUN git fetch origin && \
#   git checkout ebee446d7c3b9071633764b39cdca3ac1b28d253

RUN npm i

# Install Blockstream electrs (rust & other dependencies)
WORKDIR /root
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN apt install -y git clang
RUN git clone https://github.com/blockstream/electrs
WORKDIR /root/electrs
RUN git checkout new-index
RUN cargo build --release
ENV PATH="/root/electrs/target/release:${PATH}"
# Expose electrs & esplora ports
EXPOSE 60401 3002

# Clone and setup Esplora
WORKDIR /root
ENV COMMIT_SHA=9067d8bf4323d8fea4cbf637b7c11ebc528d56e5
RUN git clone https://github.com/Blockstream/esplora
WORKDIR /root/esplora
RUN git checkout ${COMMIT_SHA}
RUN npm install --unsafe-perm

# Environment variable to allow CORS from any domain for Esplora
ENV CORS_ALLOW=*
# The esplora server:
ENV API_URL="http://localhost:3002"
# Expose Esplora server
EXPOSE 5000

ENTRYPOINT ["/root/run.sh"]

# Expose regtest-server
EXPOSE 8080
