#!/bin/bash

apt-get update -y

# Download Paramify installer
export INSTALLER=/tmp/paramify.tgz
export OPT_DIR=/opt/paramify
# kURL (interactive): curl -sSL https://kurl.sh/paramify-beta | sudo bash
# Embedded Cluster (k0s):
curl -f https://replicated.app/embedded/paramify/beta -H "Authorization: ${license_id}" -o $INSTALLER && mkdir $OPT_DIR && tar -xvzf $INSTALLER -C $OPT_DIR

# Run Paramify installer -- fully automated install not yet available (defaults to "password")
if [ -f $OPT_DIR/paramify ]; then
  nohup $OPT_DIR/paramify install --license $OPT_DIR/license.yaml --no-prompt &>/tmp/paramify.log &
fi
