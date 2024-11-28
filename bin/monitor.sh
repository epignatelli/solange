CLUSTER="testnet"

# check that the validator keypair file exists
if [[ ! -f /home/sol/solange/keys/validator-keypair.json ]]; then
    echo "Error: Validator keypair file '/home/sol/solange/keys/validator-keypair.json' does not exist."
    exit 1
fi

# check that the vote keypair file exists
if [[ ! -f /home/sol/solange/keys/vote-account-keypair.json ]]; then
    echo "Error: Vote keypair file '/home/sol/solange/keys/vote-account-keypair.json' does not exist."
    exit 1
fi

# check that the ledger directory exists and has the right permissions
if [[ ! -d /mnt/ledger ]]; then
    echo "Error: Ledger directory '/mnt/ledger' does not exist."
    exit 1
fi

# check that the accounts directory exists and has the right permissions
if [[ ! -d /mnt/accounts ]]; then
    echo "Error: Accounts directory '/mnt/accounts' does not exist."
    exit 1
fi

# check that the log directory exists and has the right permissions
if [[ ! -d $HOME/solange/logs ]]; then
    echo "Error: Log directory '$HOME/solange/logs' does not exist."
    exit 1
fi

# check that the agave-validator process is running
if [[ ps aux | grep agave-validator | grep -v grep ]] || {
    echo "Error: agave-validator is not running."
    exit 1
}

# print the logs
cat $HOME/solange/logs/agave-validator.log

# check that the validator has registered to the gossip network
IDENTITY_PUBKEY=$(solana-keygen pubkey /home/sol/solange/keys/validator-keypair.json)
if [[ ! solana gossip | grep $IDENTITY_PUBKEY ]]; then
    echo "Error: Validator has not registered to the gossip network."
    exit 1
fi

# check that the validator is ready to vote
solana validators -u $CLUSTER | grep $IDENTITY_PUBKEY || {
    echo "Error: Validator is not ready to vote."
    exit 1
}

# see is the validator is caught up with the network
solana catchup -u $CLUSTER $IDENTITY_PUBKEY