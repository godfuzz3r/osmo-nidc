#!/bin/bash
while true; do
    clear
    curl 'http://127.0.0.1:8081/get_active?format=text'
    sleep 1
done