#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "./send-sms.sh <from> <to> <text>"
    echo "examples:"
    echo "      ./send-call.sh 9999 601 /sounds/tt-monkeys"
    echo "       filename starting from /sounds/ means your files from ./vol/asterisk_sounds/"
    echo "       filename without path means default sound library from /usr/share/asterisk/sounds/"
    exit
fi

curl -v http://127.0.0.1:8081/call --json "{\"caller_extension\": \"$1\", \"dest\": \"$2\", \"voice_file\": \"$3\"}"