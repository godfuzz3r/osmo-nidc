#!/bin/bash
docker compose exec osmo 'tcpdump' -i any -U -s0 -w - 'udp port 23000 or udp port 4729' | wireshark -k -i -
