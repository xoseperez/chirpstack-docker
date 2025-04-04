#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    create role chirpstack with login password 'chirpstack';
    create database chirpstack with owner chirpstack;
    create database chirpstack_fuota with owner chirpstack;
EOSQL
