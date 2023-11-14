#!/bin/bash

export ARCH=arm64
export MODEL=RAK5146
export BAND=eu868
export CHIRPSTACK_GATEWAY_BRIDGE_HOSTS=127.0.0.1,localhost,192.168.42.137
export MQTT_BROKER_HOSTS=127.0.0.1,localhost,192.168.42.137
export API_SECRET=e0A0dkoGQxqdX8R4g3l2XYg/uFGHZy+VGtyov6juszo=

docker compose -p chirpstack -f docker-compose.yml -f docker-compose-bridge-udp.yml -f docker-compose-bridge-basicstation.yml up -d
#docker compose -p chirpstack -f docker-compose.yml -f docker-compose-concentratord.yml -f docker-compose-mqtt-forwarder.yml up -d
#docker compose -p chirpstack  -f docker-compose.yml -f docker-compose-concentratord.yml -f docker-compose-bridge-concentratord.yml up -d