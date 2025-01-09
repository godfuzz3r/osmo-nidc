#!/bin/bash
docker compose exec osmo \
    bash -c "echo 'show pdp-context all' | nc -q 1 localhost 4245"