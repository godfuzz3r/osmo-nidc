#!/bin/bash
docker compose exec osmo \
    bash -c "telnet localhost 4258"
