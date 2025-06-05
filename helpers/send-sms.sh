#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "./send-sms.sh <from> <to> <text>"
    echo "examples:"
    echo "      ./send-sms.sh osmo 222 hello"
    echo "      ./send-sms.sh "acii text" all hello # broadcast sms"
    exit
fi

curl -v http://127.0.0.1:8081/sms --header "Content-Type: application/json" --request POST --data "{\"source\": \"$1\", \"dest\": \"$2\", \"text\": \"$3\"}"