#!/bin/bash

# check how much behind the ledger is
solana catchup /mnt/ledger

# if the ledger is more than 100 slots behind, update it
if [ $? -eq 1 ]; then
    solana catchup /mnt/ledger
fi