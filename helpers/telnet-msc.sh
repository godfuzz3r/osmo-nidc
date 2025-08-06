#!/bin/bash
docker compose exec osmo-pentools \
    bash -c "telnet localhost 4254"