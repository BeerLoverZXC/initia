FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && \
apt-get install curl git wget tmux build-essential jq make lz4 unzip -y

ENV HOME=/app \
NODENAME="Stake Shark" \
CHAIN_ID="interwoven-1" \
GO_VER="1.22.3" \
WALLET="wallet" \
PATH="/usr/local/go/bin:/app/go/bin:${PATH}" \
DAEMON_NAME=initiad \
DAEMON_HOME=/app/.initia \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true \
SEEDS="e95db1364ae57dda698e928e497d2133ae49d7c3@initia-mainnet-seed.itrocket.net:30656" \
PEERS="448d04e003831705629c38c4c353fb80f123bc51@initia-mainnet-peer.itrocket.net:30656,324f78a74e1d3cd10db8b4c3b92e5b3239a7a27e@47.76.189.32:26656,b58e3dacc8c8009514c14e36730b564962028adc@34.124.183.130:26656,c863880bc9503d54e4b60f67fb52738f0b26a3f6@47.238.252.164:26656,e5f648851f02aa0b17a8c128dddef3821bf89194@57.128.230.96:60156,e5e95f2081cec4cbd41c4739be0ee70fb9da7e36@46.17.103.41:25756,ea7998bae60735274e8839adad4791b4d9f5dfa6@57.129.37.198:26656,80e8870743458d1a28ce9f9da939e4ddcb7cedfe@34.142.172.124:26656,865be42b69248ff8ae1c17ae38ae9d62520d5434@148.251.87.13:26656,fa415de39e343593e0200c665da3bec634ce76f0@148.113.193.107:26656,c02d9c632bcbc7af974399c122eae36a8ed466bb@34.126.106.6:26656"

WORKDIR /app

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

RUN git clone https://github.com/initia-labs/initia.git && \
cd initia && \
git checkout v1.0.0 && \
make install && \
mkdir -p $HOME/.initia/cosmovisor/genesis/bin && \
mv /app/go/bin/initiad $HOME/.initia/cosmovisor/genesis/bin/

RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

RUN /app/.initia/cosmovisor/genesis/bin/initiad init "Stake Shark" && \
/app/.initia/cosmovisor/genesis/bin/initiad config set client chain-id $CHAIN_ID && \
/app/.initia/cosmovisor/genesis/bin/initiad config set client node tcp://localhost:26657 && \
sed -i -e "s|^node *=.*|node = \"tcp://localhost:26657\"|" $HOME/.initia/config/client.toml

RUN wget -O $HOME/.initia/config/genesis.json https://server-3.itrocket.net/mainnet/initia/genesis.json && \
wget -O $HOME/.initia/config/addrbook.json  https://server-3.itrocket.net/mainnet/initia/addrbook.json


RUN sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):26656\"/" $HOME/.initia/config/config.toml && \
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.015uinit\"|" $HOME/.initia/config/app.toml && \
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 40/g' $HOME/.initia/config/config.toml && \
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 10/g' $HOME/.initia/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.initia/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.initia/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.initia/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.initia/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.initia/config/config.toml && \
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.initia/config/app.toml && \
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
       $HOME/.initia/config/config.toml

RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
