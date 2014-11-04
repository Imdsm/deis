#!/usr/bin/env bash
#
# Usage: ./provision-rackspace-cluster.sh <key pair name> [environment] [flavor]
#

set -e

THIS_DIR=$(cd $(dirname $0); pwd) # absolute path
CONTRIB_DIR=$(dirname $THIS_DIR)

source $CONTRIB_DIR/utils.sh

if [ -z "$1" ]; then
  echo_red 'Usage: provision-rackspace-cluster.sh <key pair name> [environment] [flavor]'
  exit 1
fi

if [ -z "$2" ]; then
  ENV="production"
else
  ENV=$2
fi

if [ -z "$3" ]; then
  FLAVOR="performance1-2"
else
  FLAVOR=$3
fi

if ! which supernova > /dev/null; then
  echo_red 'Please install the dependencies listed in the README and ensure they are in your $PATH.'
  exit 1
fi

if ! supernova $ENV network-list|grep -q deis &>/dev/null; then
  echo_yellow "Creating deis private network..."
  supernova $ENV network-create deis 10.21.12.0/24
fi

NETWORK_ID=`supernova $ENV network-list|grep deis|awk -F"|" '{print $2}'|sed 's/^ *//g'`

if [ -z "$DEIS_NUM_INSTANCES" ]; then
    DEIS_NUM_INSTANCES=3
fi

# check that the CoreOS user-data file is valid
$CONTRIB_DIR/util/check-user-data.sh

i=1 ; while [[ $i -le $DEIS_NUM_INSTANCES ]] ; do \
    echo_yellow "Provisioning deis-$i..."
    # this image is CoreOS 452.0.0
    supernova $ENV boot --image 7f116bdd-9b17-410c-b049-eb1bca1b7087 --flavor $FLAVOR --key-name $1 --user-data ../coreos/user-data --no-service-net --nic net-id=$NETWORK_ID --config-drive true deis-$i ; \
    ((i = i + 1)) ; \
done

echo_green "Your Deis cluster has successfully deployed to Rackspace."
echo_green "Please continue to follow the instructions in the README."
