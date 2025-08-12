#!/usr/bin/env python3

while ! nc -z $NIDC_HOST 2775; do
    echo 'waiting for smpp'
    sleep 0.1
done

while ! nc -z $NIDC_HOST 12345; do
    echo 'waiting for cbc'
    sleep 0.1
done

while ! nc -z $NIDC_HOST 4255; do
    echo 'waiting for msc ctrl'
    sleep 0.1
done

while ! nc -z $NIDC_HOST 4254; do
    echo 'waiting for msc vty'
    sleep 0.1
done

while ! nc -z $NIDC_HOST 4258; do
    echo 'waiting for hlr vty'
    sleep 0.1
done

while ! nc -z $NIDC_HOST 4245; do
    echo 'waiting for sgsn vty'
    sleep 0.1
done
sleep 3
python3 /app/app.py &
python3 /app/do_interactions.py