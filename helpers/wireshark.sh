#!/bin/bash
docker compose exec osmo 'tcpdump' -i apn0 -U -s0 -w - | wireshark -k -i -
