#!/usr/bin/env python3
import yaml
import os
import time
from utils import get_active_subscribers_imsi, get_active_subscribers_dict
from utils import send_sms, send_ussd, send_call

cached_subscribers = {}


def get_interaction_subscribers():
    global cached_subscribers
    new_subs = []
    subscribers = get_active_subscribers_dict()
    for imsi, msisdn in subscribers.items():
        if imsi not in cached_subscribers:
            new_subs.append({"imsi": imsi, "msisdn": msisdn})
            cached_subscribers[imsi] = msisdn
    return new_subs


def clear_expired_cache():
    global cached_subscribers
    subscribers = get_active_subscribers_imsi()
    need_delete = []
    for imsi in cached_subscribers:
        if imsi not in subscribers:
            need_delete.append(imsi)

    for imsi in need_delete:
        del cached_subscribers[imsi]


cached_stamp = 0
filename = (
    "/configs/config.yml" if os.getenv("DOCKER_ENV") else "../../configs/config.yml"
)
config = {}
while True:
    time.sleep(1)
    stamp = os.stat(filename).st_mtime
    if stamp != cached_stamp:
        cached_stamp = stamp
        print("loading new config file", flush=True)
        config = yaml.load(open(filename), Loader=yaml.SafeLoader)

    if "interaction" not in config:
        continue

    # no need to interaction if all disabled
    if not any([x["enabled"] for x in config["interaction"].values()]):
        continue

    for sub in get_interaction_subscribers():
        print(f"interacting with {sub}", flush=True)
        if config["interaction"]["sms"]["enabled"]:
            send_sms(
                source=config["interaction"]["sms"]["sender"],
                dest=sub["msisdn"],
                text=config["interaction"]["sms"]["text"],
            )

        if config["interaction"]["ussd"]["enabled"]:
            send_ussd(
                msisdn=sub["msisdn"],
                type=str(config["interaction"]["ussd"]["type"]),
                text=config["interaction"]["ussd"]["text"],
            )

        if config["interaction"]["call"]["enabled"]:
            send_call(
                caller_extension=str(config["interaction"]["call"]["from"]),
                extension=sub["msisdn"],
                voice_file=config["interaction"]["call"]["voice-file"],
            )

    clear_expired_cache()
