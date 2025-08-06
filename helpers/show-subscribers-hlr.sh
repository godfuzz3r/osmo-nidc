#!/bin/bash
docker compose exec osmo-pentools \
    bash -c "echo 'show subscribers all' | nc -q 1 localhost 4258"