# Lagrange Labs State Committees Client Node

Lagrange Labs State Committees provide a mechanism for generating succinct zero-knowledge state proofs for optimistic rollups based on the use of either staked or restaked collateral. Each state committee is a group of validators that have either staked an optimistic rollup’s native token or dualstaked with EigenLayer. Each state committee node attests to the execution and finality of transaction batches submitted by optimistic sequencers to Ethereum.

Whenever a rollup block is considered either safe (OP stack) or has had its corresponding transaction batch settled on Ethereum (Arbitrum), each node is required to attest to the block using its BLS key.

Broadly, each signature is executed on a tuple containing 3 essential elements:

```
struct block {
    var block_header,
    var current_committee,
    var next_committee
}
```

For a full breakdown of the architecture, please refer to the below two documents:

1. [Lagrange Technical Overview Docs](https://lagrange-labs.gitbook.io/lagrange-labs/lagrange-state-committees/commitees-overview)
2. [Lagrange State Committee Deep Dive](https://hackmd.io/@lagrange/lagrange-committee)

## Running a Lagrange Client Node

For the purpose of demonstrating how to run a Lagrange Attestation Node, we've created a Lagrange Operator Network. The below commands will allow a developer to run a node and attest to the state of `Optimism`, `Arbitrum` and/or `Mantle` Sepolia Network.

### Chains

- Optimism: `11155420`
- Arbitrum: `421614`
- Mantle: `5003`

### Minimum Recommended Hardware

- RAM: `1 GB`
- Storage: `8 GB`
- AWS instance type: `t2.micro`
- Architecture: 64-bit ARM instance

> Note: The commands in this README file are for 64-bit ARM AWS ubuntu instance.

### Pre-requisite Installations

1. Golang

```bash
sudo apt-get update
sudo apt-get -y upgrade
wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
sudo tar -xvf go1.20.14.linux-amd64.tar.gz -C /usr/local
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
export GOROOT=/usr/local/go
source ~/.profile
go version
```

2. Docker and Docker Compose

```bash
sudo apt-get update
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin make
echo '{ "log-opts": { "max-size": "10m", "max-file": "100" } }' | sudo tee /etc/docker/daemon.json
sudo usermod -aG docker $USER
newgrp docker
sudo systemctl restart docker
docker login -u <username>
```

## Steps

1. Create a new Ethereum address using a wallet like Metamask.
2. Send the account address to Lagrange Labs team for allowlisting.
3. Clone the [Lagrange CLI repository](https://github.com/Lagrange-Labs/client-cli) to your machine.

```bash
git clone https://github.com/Lagrange-Labs/client-cli.git
```

4. Configure GIT to use Personal Access Token (PAT).

```bash
git config --global http.https://github.com/.extraheader "Authorization: Basic $(echo -n username:your_token_here | base64)"
```

5. The CLI app has a dependency on Lagrange's private repository so run the following commands to successfully download the dependencies.

```bash
echo 'GOPRIVATE=github.com/Lagrange-Labs/' >> .profile
source .profile
export CGO_CFLAGS="-O -D__BLST_PORTABLE__"
export CGO_CFLAGS_ALLOW="-O -D__BLST_PORTABLE__"
cd client-cli
go mod download
```

6. Create a go binary.

```bash
make build
```

7. Update `ChainRPCEndpoint` and `EthereumRPCURL` in `config_<chain>.toml` for which you want to run Lagrange Attestation Node.

`ChainRPCEndpoint`: RPC endpoint for `Sepolia` network of the chain eg. `Optimism`, `Arbitrum`, `Mantle`

`EthereumRPCURL`: RPC endpoint for `Ethereum Sepolia` network.

The repository contains `config_<chain>.toml` for each supported chain which contains the required configuration like smart contract addresses and sequencer gRPC URL.

For now, we only support the `BN254` curve for the `BLSScheme`.

7. Stake your tokens by depositing them into the Lagrange Staking contracts.

```bash
./dist/lagrange-cli run -c ./config_<chain>.toml
```

> Note: You can choose config of any chain in this step as the goal is to deposit sepolia ETH into the Lagrange staking contract.

- Enter `d` in the prompt to start the deposit process which will add funds to the Lagrange Staking Contract.

  - Enter your `ECDSA private key`

    > Note: Please enter the dummy Ethereum address created above and not your personal address that contains real valued assets.

  - Enter your token address.
  - Enter the staking amount.

8. After successfully completing the staking process, start the Lagrange Attestation Node deployment process.

The following commands needs to run for every chain you want to register and deploy the Lagrange Attestation Nodes.

```bash
./dist/lagrange-cli run -c ./config_<chain>.toml
```

- Enter `r` in the prompt to run the deployment steps.
  - Enter the chain name.
    > Note: Make sure that the `config_<chain>.toml` should be for the same chain name in the command.
  - Enter your `ECDSA private key`
    > Note: Please enter the dummy Ethereum address created above and not your personal address that contains real valued assets.
  - Enter `y` to let the CLI randomly generate a BLS key pair or else you can enter `n` and add an already available BLS private key.
    > Note: Each Lagrange Attestation Node should have a unique BLS key pair
  - Enter `y` to register the attestation node to the Lagrange State Committee.
    > Each Lagrange Attestation Node can be subscribed to multiple chains.
  - Enter `y` to subscribe the attestation node to the chain you mentioned.
  - Enter the `chain id` for your chain.
    - If the chain subscription fails with an error `The dedicated chain is already subscribed`, you can press `n` and then enter `e` to exit.
    - If the chain subscription fails with an error `The dedicated chain is locked`, please enter `y` to retry the subscription to that chain.
  - Re-run the above command for every chain you want to subcscribe the Lagrange Attestation Node.
