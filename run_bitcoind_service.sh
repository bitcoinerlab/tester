#!/usr/bin/env bash

/usr/bin/bitcoind -server -regtest -txindex -zmqpubhashtx=tcp://127.0.0.1:30001 -zmqpubhashblock=tcp://127.0.0.1:30001 -rpcworkqueue=32 -fallbackfee=0.0002 &
disown
sleep 2
/usr/bin/bitcoin-cli -regtest createwallet default
/usr/bin/bitcoin-cli -regtest loadwallet default
ADDRESS=$(/usr/bin/bitcoin-cli -regtest getnewaddress "" bech32)
/usr/bin/bitcoin-cli -regtest generatetoaddress 432 $ADDRESS
