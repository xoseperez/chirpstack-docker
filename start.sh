#!/bin/bash

export ARCH=arm64
export MODEL=RAK5146
export BAND=eu868
export HOSTS=127.0.0.1,localhost
export CHIRPSTACK_GATEWAY_BRIDGE_HOSTS=$HOSTS
export MQTT_BROKER_HOSTS=$HOSTS
export API_SECRET=e0A0dkoGQxqdX8R4g3l2XYg/uFGHZy+VGtyov6juszo=
export NET_ID=000000
export PUID=$( id -u )
export PGID=$( id -g )
export PGID_GPIO=$( grep ^gpio /etc/group | cut -d':' -f3 )
export PGID_I2C=$( grep ^i2c /etc/group | cut -d':' -f3 )
export PGID_SPI=$(  grep ^spi /etc/group | cut -d':' -f3 )

declare SERVICES=(
    chirpstack
    bridge-udp
    bridge-basicstation 
    #concentratord
    #mqtt-forwarder
)

FILES=""
for i in "${!SERVICES[@]}"; do
    FILES="$FILES -f docker-compose-${SERVICES[i]}.yml "
done

docker compose -p chirpstack "$FILES" up -d
