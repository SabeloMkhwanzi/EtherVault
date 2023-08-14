# Foundry Smart Contract EtherVault

#### [👉Here's the deployed Smart Contract](https://sepolia.etherscan.io/address/0x37d138a62be828e111e682ff7d699f47bb8dd769)

### Structure of our Project

1. Deposit any amount of ether.

- User can withdraw ether from store based on this condition

2. Address of the User must have enough ether to withdraw minimum of `1 eth`.

3. User can only withdraw only `1 eth` at the time.

4. User can only withdraw after `1 week` has completed

5. The withdrawal limit can only be change by the contract owner.

6. Contract has function to view ether balances on address and last time withdrawals made.

7. Contract also uses Chainlink data-feeds to Eth price in USD.

## Quickstart

```
git clone https://github.com/SabeloMkhwanzi/EtherVault.git
cd EtherVault
forge build
```

# Usage

Deploy:

```
forge script scripts/EtherVault.s.sol
```

## Testing

1. Unit

This repo we cover #1 and #3.

```
forge test
```

or

```
// Only run test functions matching the specified regex pattern.

"forge test -m testFunctionName" is deprecated. Please use

forge test --match-test testFunctionName
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```

# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

3. Deploy

```
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

#### happy coding 😁
