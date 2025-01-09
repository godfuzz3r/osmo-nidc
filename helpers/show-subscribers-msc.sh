#!/bin/bash
docker compose exec osmo \
    bash -c "echo 'show subscriber cache conn+trans' | nc -q 1 localhost 4254"