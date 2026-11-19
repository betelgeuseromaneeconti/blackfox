#!/bin/sh
if [ ! -f /var/lib/blackfox/config.json ] && [ -f /var/lib/arman-vpn/config.json ]; then
  mkdir -p /var/lib/blackfox
  cp -a /var/lib/arman-vpn/. /var/lib/blackfox/
fi
# Starts the core. The data folder is the volume /var/lib/blackfox.
# The first start opens the panel and the proxy to the network
# (blackfox-vpn-core -setup-server) and prints the logins.
set -eu

data=/var/lib/blackfox
mkdir -p "$data"
if [ ! -f "$data/config.json" ]; then
  blackfox-vpn-core -data-dir "$data" -setup-server=-
fi
exec blackfox-vpn-core -plain -data-dir "$data"
