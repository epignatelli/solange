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
1.1. Create a `sol` user, if you haven't already, and add it to the sudoers group
```bash
sudo adduser sol
sudo usermod -aG sudo sol
su - sol # login as sol
```
1.2 Install the solana software package
```bash
cd $HOME
bash -c $(wget https://github.com/epignatelli/solange/raw/build.sh <ledger-drive-id> <accounts-drive-id>)
```

### 2. Create accounts (on your local private computer)
2.1 Run the create_accounts script to create the SSH key pair. Options are "testnet", "devnet" or "mainnet"
```bash
bash -c $((wget https://github.com/epignatelli/solange/raw/create_accounts.sh <ledger-drive-id> <accounts-drive-id>)
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

## References
- Operating a validator: https://docs.anza.xyz/operations
- Install solana: https://docs.anza.xyz/cli/install
- Jito: https://www.jito.network/docs/jitosol/introduction-to-jito/
- Youtube workshop: https://www.youtube.com/watch?v=b0-vMyoojuo&list=PLilwLeBwGuK6jKrmn7KOkxRxS9tvbRa5p
- Solana economic design: https://solana.com/docs/core/fees#basic-economic-design
- Economy calculator: https://cogentcrypto.io/ValidatorProfitCalculator#AuBB9st3RqhHBkzZgBSm6SVnHZNJQSHeBWCSkik4bzdA
- Initiatives: https://docs.anza.xyz/operations/validator-initiatives
- Solana delegation program: https://solana.org/delegation-program
- Solblaze: https://solblaze.com/
- Marinade: https://marinade.finance/
- Validator economy articles:
  - https://laine-sa.medium.com/solana-staking-rewards-validator-economics-how-does-it-work-6718e4cccc4e
  - https://apfikunmi.medium.com/running-a-solana-validator-a95cdfd6488a#5533
  - https://medium.com/@aadesolaade2341/decoding-solana-unraveling-the-role-of-validators-and-fee-economics-bd3eb40a08c3