#!/bin/bash

# make sure the clock is in sync
timedatectl | grep "synchronized: yes" || {
    sudo systemctl stop systemd-timesyncd
    sudo ntpdate -s time.nist.gov
    sudo systemctl start systemd-timesyncd
}

# start the validator
exec agave-validator \
    --identity /home/sol/solange/keys/validator-keypair.json \
    --vote-account /home/sol/solange/keys/vote-account-keypair.json \
    --log /home/sol/solange/logs/agave-validator.log \
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
