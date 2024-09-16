#!/bin/sh

BASEDIR=$(dirname "$0")

SITES_MAP_FILE=$BASEDIR"/sitesMap.yaml"

DESTINATION_DIR=$1

# Loop through each site in the YAML file
yq -r '.sites[] | [.map, .to, .php] | @sh' "$SITES_MAP_FILE" | while IFS= read -r line; do
  # Read the values into variables
  eval "set -- $line"
  MAP=$1
  TO=$2
  PHP=$3
  eval "sh $BASEDIR/nginx.sh $MAP $DESTINATION_DIR/$TO 80 443 $PHP"
done



