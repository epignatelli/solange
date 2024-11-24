# This file sets up a new agave voting validator

# set versions
SOL_VERSION="2.0.16"
TOOLS_VERSION="1.43"

# tidy
mkdir -p solana
cd solana

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install base prerequisites
apt-get install \
    build-essential \
    pkg-config \
    libudev-dev llvm libclang-dev \
    protobuf-compiler

# fetch and inflate platform-tools
wget https://github.com/anza-xyz/platform-tools/archive/refs/tags/v$TOOLS_VERSION.tar.gz
tar xvf "v$TOOLS_VERSION".tar.gz

# build platform-tools
cd platform-tools-$TOOLS_VERSION
chmod 777 ./build.sh
./build.sh

# fetch and inflate solana source
wget https://github.com/anza-xyz/agave/archive/refs/tags/v$SOL_VERSION.tar.gz
tar xvf "$SOL_VERSION.tar.gz"

# build
./scripts/cargo-install-all.sh .
export PATH=$PWD/bin:$PATH
cd agave-$SOL_VERSION
agave-install init
