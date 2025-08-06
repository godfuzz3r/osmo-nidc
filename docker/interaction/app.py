#!/usr/bin/env python3
from flask import Flask, request, g
import json
from utils import (
    send_sms,
    send_ussd,
    get_active_subscribers_msisdn,
    get_active_subscribers_info,
    send_call,
)

app = Flask(__name__)


@app.route("/")
def index():
    return "hello"


@app.route("/sms", methods=["POST"])
def sms_route():
    body = request.get_json()
    if not set(["source", "dest", "text"]).issubset(body.keys()):
        return (
            """need json with next structure:\n{\n\t"source": "sender",\n\t"dest", "recepient",\n\t"text": "text"\n}""",
            401,
        )
    if body["dest"] == "*" or body["dest"] == "all":
        for dest in get_active_subscribers_msisdn():
            send_sms(body["source"], dest, body["text"])
    else:
        send_sms(body["source"], body["dest"], body["text"])
    return "ok"


@app.route("/ussd", methods=["POST"])
def ussd_route():
    body = request.get_json()
    utype = "0"
    if "type" in body:
        utype = body["type"]

    if not set(["dest", "text"]).issubset(body.keys()):
        return (
            """need json with next structure:\n{\n\t"type": "0|1|2",\n\t"dest", "recepient"}""",
            401,
        )
    if body["dest"] == "*" or body["dest"] == "all":
        for dest in get_active_subscribers_msisdn():
            send_ussd(dest, utype, body["text"])
    else:
        send_ussd(body["dest"], utype, body["text"])
    return "ok"


@app.route("/call", methods=["POST"])
def call_route():
    body = request.get_json()
    if not set(["dest"]).issubset(body.keys()):
        return (
            """need json with next structure:\n{\n\t"caller_extension": "123",\n\t"dest", "456",\n\t"voice_file": "tt-monkeys"}""",
            401,
        )
    dest = body.get("dest")
    caller_extension = body.get("caller_extension")
    voice_file = body.get("voice_file")
    if not caller_extension:
        caller_extension = ""
    if not voice_file:
        voice_file = "tt-monkeys"

    if dest == "*" or dest == "all":
        for d in get_active_subscribers_msisdn():
            send_call(caller_extension, d, voice_file)
    else:
        send_call(caller_extension, dest, voice_file)
    return "ok"


@app.route("/get_active")
def get_active():
    active = get_active_subscribers_info()
    if request.args.get("format") == "text":
        if active:
            apn_max_len = max((len(sub["apn"]) for sub in active))
            max_ul_len = max((len(sub["ul"]) for sub in active))
            max_dl_len = max((len(sub["dl"]) for sub in active))
            ipv4_ul_len = max((len(sub["ipv4"]) for sub in active))
            ipv6_dl_len = max((len(sub["ipv6"]) for sub in active))
        else:
            apn_max_len = max_ul_len = max_dl_len = ipv4_ul_len = ipv6_dl_len = 0
        out = f"id\tmsisdn\timsi\t\timei\t\t| {'apn':<{apn_max_len}}\t{'UL':<{max_ul_len}}\t{'DL':<{max_dl_len}}\t{'IPv4':<{ipv4_ul_len}}\t{'IPv6':<{ipv6_dl_len}}\n"
        for sub in active:
            out += f"{sub['id']}\t{sub['msisdn']}\t{sub['imsi']}\t{sub['imei']}\t| "
            out += f"{sub['apn']:<{apn_max_len}}\t{sub['ul']}\t{sub['dl']}\t{sub['ipv4']}\t{sub['ipv6']}\n"
        return out
    return json.dumps(active)


app.run(host="127.0.0.1", port=8081, debug=True)
