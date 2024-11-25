# SOLANGE: Plug-and-play solana node startup for developers

**[Quickstart](#what-is-solange)** | **[Install](#installation)** | **[Execution](#execution)** | **[Monitoring](#monitoring)** | **[Examples](#examples)** |

</div>

## What is SOLANGE?
Solange is a plug-and-play solana node startup for developers.
It is a set of scripts that allow you to start a solana node with a single command.

## Installation
1. On the validator machine, run the `build.sh` installation script
2. On your private computer, run the `create_accounts.sh` script to create the SSH key pair that you will use to connect to your solana validator node, and your vote account
3. Copy to the solana validator node machine:
   1. Validator key
   2. Vote account key

### 1. Install the solana validator node (on the validator machine)
1. Create a `sol` user, if you haven't already, and add it to the sudoers group
```bash
sudo adduser sol
sudo usermod -aG sudo sol
```
2. Log in as the `sol` user
```bash
su - sol
```
3. Clone the repository
```bash
cd $HOME
git clone https://github.com/epignatelli/solange.git
```
4. Run the build script to install all the necessary dependencies
```bash
cd solange
chmod +x build.sh <ledger-drive-id> <accounts-drive-id>
./build.sh
```
### 2. Create the SSH key pair (on your local private computer)
1. Clone the repository
```bash
cd $HOME
git clone https://github.com/epignatelli/solange.git
```
1. Run the create_accounts script to create the SSH key pair. Options are "testnet", "devnet" or "mainnet"
```bash
cd solange
chmod +x create_accounts.sh "testnet"
./create_accounts.sh
```
### 3. Copy the SSH key to the validator machine
```bash
validator_pubkey=$(solana-keygen pubkey $HOME/solange/validator-keypair.json)
vote_pubkey=$(solana-keygen pubkey $HOME/solange/vote-account-keypair.json)
echo $validator_pubkey > $HOME/solange/validator.pub
echo $vote_pubkey > $HOME/solange/vote.pub
```
```bash
scp $HOME/solange/validator.pub sol@$<address-of-validator>:/home/sol/solange/validator.json
scp $HOME/solange/vote.pub sol@$address-of-validator:/home/sol/solange/vote.json
```

## Execution


## Monitoring
Checks how many slots behind the validator is, and if it is syncing
```bash
solana catchup <validator-pubkey>
```

Displays information about the validator progressing through the slots
```bash
solana-validator -l <path-to-ledger> monitor
```

The command solana gossip lists all validators that have registered with the protocol.
```bash
solana gossip | grep <validator-pubkey>
```

## Examples
TODO
