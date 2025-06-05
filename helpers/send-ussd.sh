#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "./send-ussd.sh <type = (0|1|2)> <dest> <text>"
    echo "examples:"
    echo "      ./send-ussd.sh 0 111 ping"
    echo "      ./send-ussd.sh 0 all ping # broadcast"
    exit
fi

echo "{\"type\": \"$1\", \"dest\": \"$2\", \"text\": \"$3\"}"
curl -v http://127.0.0.1:8081/ussd --header "Content-Type: application/json" --request POST --data "{\"type\": \"$1\", \"dest\": \"$2\", \"text\": \"$3\"}"