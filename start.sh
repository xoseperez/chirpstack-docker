#!/bin/bash

INTERFACE=$( tail -n+3 < /proc/net/dev | sort -k2 -nr | head -n1 | cut -d ":" -f1 | sed 's/ //g' )
IP=$( ip a show "$INTERFACE" | awk '/inet / {print $2}' | awk -F/ '{print$1}' )

export ARCH=arm64
export MODEL=RAK5146
export INTERFACE=USB
export RESET_GPIO=17
export BAND=eu868
export HOSTS=127.0.0.1,localhost,$IP
export CHIRPSTACK_GATEWAY_BRIDGE_HOSTS=$HOSTS
export MQTT_BROKER_HOSTS=$HOSTS
export API_SECRET=e0A0dkoGQxqdX8R4g3l2XYg/uFGHZy+VGtyov6juszo=
export NET_ID=000000
export PUID=$( id -u )
export PGID=$( id -g )
export PGID_GPIO=$( grep ^gpio /etc/group | cut -d':' -f3 )
export PGID_I2C=$( grep ^i2c /etc/group | cut -d':' -f3 )
export PGID_SPI=$(  grep ^spi /etc/group | cut -d':' -f3 )

# Example setups:

# LoRaWAN Gateway with local ChirpStack LNS: concentratord + mqtt-forwarder + chirpstack
# LoRaWAN Gateway using MQTT Forwarder to external ChirpStack LNS: concentratord + mqtt-forwarder
# LoRaWAN Gateway using UDP Forwarder to external LNS: concentratord + udp-forwarder
# LoRaWAN Gateway Mesh Relay Gateway: concentratord + gateway-mesh
# LoRaWAN Gateway Mesh Border Gateway to an external ChirpStack LNS: concentratord + gateway-mesh + mqtt-forwarder
# LoRaWAN Gateway Mesh Border Gateway to local ChirpStack LNS: concentratord + gateway-mesh + mqtt-forwarder + chirpstack
# ChirpStack LNS: chirpstack + bridge-basicstation + bridge-udp


declare SERVICES=(
    chirpstack
    #bridge-basicstation 
    #bridge-udp
    #bridge-concentratord
    concentratord
    #gateway-mesh
    mqtt-forwarder
    #udp-forwarder
)

FILES=""
for i in "${!SERVICES[@]}"; do
    FILES="${FILES} -f docker-compose-${SERVICES[i]}.yml "
done

docker compose -p chirpstack ${FILES} up -d 

echo "Open Chirpstack WebUI at http://${IP}:8080"
