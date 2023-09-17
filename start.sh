#!/bin/bash

export ARCH=arm64
export MODEL=RAK5148
export BAND=ism2400
export CHIRPSTACK_GATEWAY_BRIDGE_HOSTS=127.0.0.1,localhost
export MQTT_BROKER_HOSTS=127.0.0.1,localhost
export API_SECRET=e0A0dkoGQxqdX8R4g3l2XYg/uFGHZy+VGtyov6juszo=

docker compose -f docker-compose.yml -f docker-compose-concentratord.yml -f docker-compose-bridge-concentratord.yml up -d