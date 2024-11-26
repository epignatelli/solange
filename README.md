<div align="center">

# SOLANGE: Building and executing solana validators

**[Quickstart](#what-is-solange)** | **[Setup](#setup-the-node)** | **[Execution](#execute-the-node)** | **[Monitoring](#monitoring)** | **[Examples](#examples)**

</div>

## What is SOLANGE?
Solange is a set of scripts to build and execute a solana validator node. It is designed to be a plug-and-play solution for developers who want to run a validator node on the solana network.

## Setup the node
### 1. [On validator machine] Install solana on validator node
```bash
bash -c "$(curl 'https://raw.githubusercontent.com/epignatelli/solange/refs/heads/main/install/build.sh?token=GHSAT0AAAAAACJTRNOPSLPSV6IAYGVK6R6UZ2GGYTQ')"
```

### 2. [On personal machine] Create accounts
```bash
bash -c "$(curl 'https://raw.githubusercontent.com/epignatelli/solange/refs/heads/main/install/create_accounts.sh?token=GHSAT0AAAAAACJTRNOOEO7EG56BL45GNONSZ2GGTGA' --network 'testnet')"
```
### 3. [On personal machine] Copy the pub keys to the validator machine
```bash
bash -c "$(curl 'https://raw.githubusercontent.com/epignatelli/solange/refs/heads/main/install/transfer_keys.sh?token=GHSAT0AAAAAACJTRNOP3KC3AQTF55JFXGTMZ2GHM5A' --remote-host latte)"
```

## Execute the node
The installation script creates a systemd service that runs the validator. You can start the service with the following command:
```bash
sudo systemctl start solana-validator
```


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