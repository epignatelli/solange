# This file sets up a new agave voting validator
# building solana from source. This should optimise
# the validator for the specs of each machine 

# set versions
SOL_VERSION="2.0.16"
TOOLS_VERSION="1.43"

# tidy
mkdir -p solana
cd solana

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# add cargo to path
export PATH="$HOME/.cargo/bin:$PATH"

# install base prerequisites
apt-get install \
    build-essential \
    pkg-config \
    libudev-dev llvm libclang-dev \
    protobuf-compiler


# fetch and inflate solana source
wget https://github.com/anza-xyz/agave/archive/refs/tags/v$SOL_VERSION.tar.gz
tar xvf "$SOL_VERSION.tar.gz"

# cd to agave
cd agave-$SOL_VERSION

# build
./scripts/cargo-install-all.sh .

# add agave to path
export PATH=$PWD/bin:$PATH
agave-install init $SOL_VERSION
