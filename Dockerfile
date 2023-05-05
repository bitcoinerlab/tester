# Build: docker build -t tester .
# Run: docker run -d -p 8080:8080 -p 60401:60401 -p 3002:3002 tester

# This Dockerfile is a fork from:
# https://github.com/bitcoinjs/regtest-server/tree/master/docker
# All credit should go to Jonathan Underwood.

FROM ubuntu:18.04
LABEL maintainer="José Luis Landabaso @bitcoinerlab"

RUN apt update && apt install -y software-properties-common

RUN apt update && \
   apt install -y \
   curl \
   wget \
   tar \
   python \
   build-essential \
   gnupg2 \
   libzmq3-dev \
   libsnappy-dev && \
   curl --silent --location https://deb.nodesource.com/setup_10.x | bash -

WORKDIR /root

COPY achow.asc ./

RUN gpg --import achow.asc && \
  wget https://bitcoincore.org/bin/bitcoin-core-22.0/SHA256SUMS && \
  wget https://bitcoincore.org/bin/bitcoin-core-22.0/SHA256SUMS.asc && \
  wget https://bitcoincore.org/bin/bitcoin-core-22.0/bitcoin-22.0-x86_64-linux-gnu.tar.gz && \
  sha256sum --ignore-missing --check SHA256SUMS && \
  (gpg --verify SHA256SUMS.asc 2>&1 | grep "Good signature from \"Andrew Chow" || exit 1) && \
  tar xvf bitcoin-22.0-x86_64-linux-gnu.tar.gz && \
  rm -f bitcoin-22.0-x86_64-linux-gnu.tar.gz SHA256SUM* achow.asc && \
  cp -R bitcoin-22.0/* /usr/ && \
  rm -rf bitcoin-22.0/

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

RUN git clone https://github.com/bitcoinjs/regtest-server.git
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

ENTRYPOINT ["/root/run.sh"]

EXPOSE 8080
