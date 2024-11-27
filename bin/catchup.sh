#!/bin/bash

SLOTS_BEHIND_THRESHOLD=100

# check how much behind the ledger is
solana catchup /mnt/ledger

# if the ledger is more than $SLOTS_BEHIND_THRESHOLD slots behind, update it
if [ $? -eq 1 ]; then
    solana catchup /mnt/ledger
fi

solana gossip