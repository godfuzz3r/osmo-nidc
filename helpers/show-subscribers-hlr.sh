#!/bin/bash
docker compose exec osmo \
    bash -c "echo 'show subscribers all' | nc -q 1 localhost 4258"