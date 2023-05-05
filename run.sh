#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
$DIR/run_bitcoind_service.sh

#Run electrs:
/usr/bin/bitcoin-cli -regtest getblockchaininfo # wait until the chain is synced...
#Note the 0.0.0.0 -> This is done so that it binds to 0.0.0.0 which means
#that it can accept calls from any external address. default is 127.0.0.1 which
#would anly let accept connections within the Docker image
electrs -vvvv --electrum-rpc-addr 0.0.0.0:60401 --http-addr 0.0.0.0:3002 --daemon-dir /root/.bitcoin --db-dir /root/electrs/db --network regtest &

export RPCCOOKIE=/root/.bitcoin/regtest/.cookie
export KEYDB=/root/regtest-data/KEYS
export INDEXDB=/root/regtest-data/db
export ZMQ=tcp://127.0.0.1:30001
export RPCCONCURRENT=32
export RPC=http://localhost:18443
export PORT=8080

node /root/regtest-server/index.js

