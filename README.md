# Docker Image

This Dockerfile and the surrounding bash scripts will create a Docker image that
runs a regtest instance alongside an HTTP server running on port 8080, which is
designed to be used with the regtest-client npm library. It also
installs and runs Blockstream's electrs server with an Esplora backend running
on port 3002 and an Electrum server on port 60401. Finally, it also installs
Blockstream's esplora Web server running on port 5000.

## Docker Hub

Bitcoinerlab maintains an image of this Dockerfile as
`bitcoinerlab/tester` on Docker Hub.

```bash
# Automatically downloads the image from Docker Hub
docker run -d -p 8080:8080 -p 60401:60401 -p 3002:3002 -p 5000:5000 bitcoinerlab/tester
```

## Build

If you prefer to build the image on your own, navigate to this folder and run:

```bash
docker build -t tester .
```

## Run

After building, you will have a local image called tester, which you can run
with the following command:

```bash
docker run -d -p 8080:8080 -p 60401:60401 -p 3002:3002 -p 5000:5000 tester
```

## Multi-Platform Build and Push to Docker Hub

```bash
docker buildx create --name mybuilder --bootstrap --use
docker login

docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t bitcoinerlab/tester . --push

# if building v7 fails (the OS may kill the compilation process for being too high)

# then discard it

docker buildx build --platform linux/amd64,linux/arm64 -t bitcoinerlab/tester:latest --push .
```

## Credits

This testing environment is a fork of
[Bitcoinjs-lib's regtest-server docker testing setup files](https://github.com/bitcoinjs/regtest-server/tree/master/docker),
with the addition of an Esplora/Electrum server.
