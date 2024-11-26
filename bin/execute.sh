#!/bin/bash

# make sure the clock is in sync
timedatetctl | grep "synchronized: yes" || {
    sudo systemctl stop systemd-timesyncd
    sudo ntpdate -s time.nist.gov
    sudo systemctl start systemd-timesyncd
}

# start the validator
exec agave-validator \
    --identity /home/sol/solange/keys/validator-keypair.json \
    --vote-account /home/sol/solange/keys/vote-account-keypair.json \
    --known-validator 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on \
    --known-validator 7XSY3MrYnK8vq693Rju17bbPkCN3Z7KvvfvJx4kdrsSY \
    --known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \
    --known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \
    --only-known-rpc \
    --no-snapshot-fetch \
    --log /home/sol/solange/bin/agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --rpc-port 8899 \
    --dynamic-port-range 8000-8020 \
    --entrypoint entrypoint.testnet.solana.com:8001 \
    --entrypoint entrypoint2.testnet.solana.com:8001 \
    --entrypoint entrypoint3.testnet.solana.com:8001 \
    --expected-genesis-hash 4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size
