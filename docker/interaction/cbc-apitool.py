#!/usr/bin/env python3
#
# (C) 2020-2021 by Harald Welte <laforge@osmocom.org>
#
# SPDX-License-Identifier: MIT
#
# This is a simplistic program to show how the REST API of osmo-cbc can be used to
# create and delete Cell Broadcast Messages
#
# A lot of the parameters are currently hard-coded, see the 'js' variable definitions
# below.

import sys
import argparse
import requests
import json


def build_url(suffix):
    BASE_PATH = "/api/ecbe/v1"
    return "http://%s:%u%s%s" % (server_host, server_port, BASE_PATH, suffix)


def rest_post(suffix, js=None):
    url = build_url(suffix)
    if verbose:
        print("POST %s (%s)" % (url, str(js)))
    print(url)
    print(json.dumps(js))
    resp = requests.post(url, json=js)
    if verbose:
        print("-> %s" % (resp))
    if not resp.ok:
        print("POST failed")
    return resp


def rest_delete(suffix, js=None):
    url = build_url(suffix)
    if verbose:
        print("DELETE %s (%s)" % (url, str(js)))
    resp = requests.delete(url, json=js)
    if verbose:
        print("-> %s" % (resp))
    if not resp.ok:
        print("DELETE failed " + str(resp))
    return resp


def do_create_cbs(args):
    js = {
        "cbe_name": "cbc_apitool",
        "category": "normal",
        "repetition_period": args.repetition_period,
        "num_of_bcast": args.num_of_bcast,
        "scope": {"scope_plmn": {}},
        "smscb_message": {
            "message_id": args.msg_id,
            "serial_nr": {
                "serial_nr_decoded": {
                    "geo_scope": "plmn_wide",
                    "msg_code": args.msg_code,
                    "update_nr": args.update_nr,
                }
            },
            "payload": {
                "payload_decoded": {
                    "character_set": args.character_set,
                    #'language': 'en',
                    "data_utf8": args.payload_data_utf8,
                    #'data_utf8': "Mahlzeit1 Mahlzeit2 Mahlzeit3 Mahlzeit4 Mahlzeit5 Mahlzeit6 Mahlzeit7 Mahlzeit8"
                    #'data_utf8': "Mahlzeit1 Mahlzeit2 Mahlzeit3 Mahlzeit4 Mahlzeit5 Mahlzeit6 Mahlzeit7 Mahlzeit8 Mahlzeit9 Mahlzeit10 Mahlzeti11 Mahlzeit12 Mahlzeit13 Mahlzeit14 Mahlzeit15 Mahlzeit16 Mahlzeit17 Mahlzeit18 Mahlzeit19 Mahlzeit20 Mahlzeit21 Mahlzeit22 Mahlzeit23 Mahlzeit24 Mahlzeit25 Mahlzeit26 Mahlzeit27 Mahlzeit28"
                }
            },
        },
    }
    rest_post("/message", js)


def do_create_etws(args):
    js = {
        "cbe_name": "cbc_apitool",
        "category": "normal",
        "repetition_period": args.repetition_period,
        "num_of_bcast": args.num_of_bcast,
        "scope": {"scope_plmn": {}},
        "smscb_message": {
            "message_id": args.msg_id,
            "serial_nr": {
                "serial_nr_decoded": {
                    "geo_scope": "plmn_wide",
                    "msg_code": args.msg_code,
                    "update_nr": args.update_nr,
                }
            },
            "payload": {
                "payload_etws": {
                    "warning_type": {"warning_type_decoded": "earthquake"},
                    "emergency_user_alert": True,
                    "popup_on_display": True,
                }
            },
        },
    }
    rest_post("/message", js)


def do_delete(args):
    rest_delete("/message/%u" % (args.msg_id))


def main(argv):
    global server_port, server_host, verbose

    parser = argparse.ArgumentParser()
    parser.add_argument("-H", "--host", help="Host to connect to", default="localhost")
    parser.add_argument(
        "-p", "--port", help="TCP port to connect to", type=int, default=12345
    )
    parser.add_argument(
        "-v", "--verbose", help="increase output verbosity", action="count", default=0
    )

    subparsers = parser.add_subparsers(required=True)

    parser_c_cbs = subparsers.add_parser("create-cbs", help="Create a new CBS message")
    parser_c_cbs.add_argument(
        "--msg-id", type=int, help="Message Identifier", required=True
    )
    parser_c_cbs.add_argument("--msg-code", type=int, help="Message Code", default=768)
    parser_c_cbs.add_argument("--update-nr", type=int, help="Update Number", default=0)
    parser_c_cbs.add_argument(
        "--repetition-period", type=int, help="Repetition Period", default=5
    )
    parser_c_cbs.add_argument(
        "--num-of-bcast", type=int, help="Number of Broadcasts", default=999
    )
    parser_c_cbs.add_argument(
        "--payload-data-utf8", type=str, help="Payload Data in UTF8", required=True
    )
    parser_c_cbs.add_argument(
        "--character-set",
        type=str,
        help="Character Set",
        default="gsm",
        choices=["gsm", "ucs2", "8bit"],
    )
    parser_c_cbs.set_defaults(func=do_create_cbs)

    parser_c_etws = subparsers.add_parser(
        "create-etws", help="Create a new ETWS message"
    )
    parser_c_etws.add_argument(
        "--msg-id", type=int, help="Message Identifier", required=True
    )
    parser_c_etws.add_argument("--msg-code", type=int, help="Message Code", default=768)
    parser_c_etws.add_argument("--update-nr", type=int, help="Update Number", default=0)
    parser_c_etws.add_argument(
        "--repetition-period", type=int, help="Repetition Period", default=5
    )
    parser_c_etws.add_argument(
        "--num-of-bcast", type=int, help="Number of Broadcasts", default=999
    )
    parser_c_etws.set_defaults(func=do_create_etws)

    parser_delete = subparsers.add_parser("delete", help="Delete a message")
    parser_delete.add_argument(
        "--msg-id", type=int, help="Message Identifier", required=True
    )
    parser_delete.set_defaults(func=do_delete)

    argv = sys.argv
    if len(sys.argv) == 1:
        args = parser.parse_args(["-h"])
    else:
        args = parser.parse_args()

    server_host = args.host
    server_port = args.port
    verbose = args.verbose

    args.func(args)


if __name__ == "__main__":
    main(sys.argv)
