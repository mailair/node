#!/bin/sh
set -eu # Exit on error and unset variables

# Wait for Bedrock node initialization
echo "Waiting for Bedrock node to initialize..."
while [ ! -f /shared/initialized.txt ]; do
  sleep 1
done

# Determine syncmode (default to snap)
OP_GETH__SYNCMODE="${OP_GETH__SYNCMODE:-snap}"
if [ "$NODE_TYPE" = "full" ]; then
  OP_GETH__SYNCMODE="full" # Override to full if NODE_TYPE is full
fi

# Override Holocene (check if set)
if [ -n "$OVERRIDE_HOLOCENE" ]; then
  EXTENDED_ARG="--override.holocene=$OVERRIDE_HOLOCENE"
fi

# Check BEDROCK_SEQUENCER_HTTP (exit if not set)
if [ -z "$BEDROCK_SEQUENCER_HTTP" ]; then
  echo "Error: BEDROCK_SEQUENCER_HTTP is not set."
  exit 1
fi

# Set port (default to 39393)
PORT__OP_GETH_P2P="${PORT__OP_GETH_P2P:-39393}"

# Start op-geth (replace current process)
exec geth \
  --op-network="$NETWORK_NAME" \
  --datadir="$BEDROCK_DATADIR" \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr="0.0.0.0" \
  --http.port=8545 \
  --http.api="eth,engine,web3,debug,net" \
  --metrics \
  --metrics.influxdb \
  --metrics.influxdb.endpoint="http://influxdb:8086" \
  --metrics.influxdb.database="opgeth" \
  --authrpc.vhosts="*" \
  --authrpc.addr="0.0.0.0" \
  --authrpc.port=8551 \
  --authrpc.jwtsecret="/shared/jwt.txt" \
  --rollup.sequencerhttp="$BEDROCK_SEQUENCER_HTTP" \
  --rollup.disabletxpoolgossip=true \
  --port="$PORT__OP_GETH_P2P" \
  --discovery.port="$PORT__OP_GETH_P2P" \
  --db.engine=pebble \
  --state.scheme=hash \
  --txlookuplimit=0 \
  --history.state=0 \
  --history.transactions=0 \
  --txpool.pricebump=10 \
  --txpool.lifetime="12h0m0s" \
  --rpc.txfeecap=4 \
  --rpc.evmtimeout=0 \
  --maxpeers=0 \
  --nodiscover \
  --gpo.percentile=60 \
  --verbosity=3 \
  --syncmode="$OP_GETH__SYNCMODE" \
  --gcmode="$NODE_TYPE" \
  "$EXTENDED_ARG" "$@" # Double quotes for variables and pass any additional arguments
