#!/usr/bin/env python3
import smpplib.gsm
import smpplib.client
import smpplib.consts
import logging
import os
from osmopy.ctrl import SynchronousCtrlConnection
from osmopy.obscvty import VTYInteract
import time
import random

logging.basicConfig(
    level=logging.DEBUG, format="%(levelname)s %(filename)s:%(lineno)d %(message)s"
)

host = os.getenv("NIDC_HOST") if os.getenv("NIDC_HOST") else "127.0.0.1"
msc_ctrl_port = 4255
msc_vty_port = 4254
sgsn_vty_port = 4245
hlr_vty_port = 4258


def get_pdp_context():
    vty = VTYInteract("OsmoSGSN", host, sgsn_vty_port)
    return_text = vty.enabled_command("show pdp-context all", close=True)

    pdp = {}
    for udata in return_text.split("PDP Context IMSI: "):
        if not udata:
            continue
        imsi = udata.split(",")[0]
        apn = udata.split("APN: ")[1].split("\n")[0].strip()
        ipv4 = ""
        ipv6 = ""
        if "IPv4" in udata:
            ipv4 = udata.split("IPv4 ")[1].split("\n")[0].strip()
        if "IPv6" in udata:
            ipv6 = udata.split("IPv6 ")[1].split("\n")[0].strip()
        download_bytes = (
            udata.split("User Data Bytes    ( In):")[1]
            .split("(")[0]
            .replace(" ", "")
            .replace("\t", "")
        )
        upload_bytes = (
            udata.split("User Data Bytes    (Out):")[1]
            .split("(")[0]
            .replace(" ", "")
            .replace("\t", "")
        )
        pdp[imsi] = {
            "apn": apn,
            "ipv4": ipv4,
            "ipv6": ipv6,
            "upload": upload_bytes,
            "download": download_bytes,
        }
    return pdp


def get_hlr():
    vty = VTYInteract("OsmoHLR", host, hlr_vty_port)
    return_text = vty.enabled_command("show subscribers all", close=True)
    subscribers = {}
    for sub in return_text.split("\r\n")[2:-1]:
        for i in range(4):
            sub = sub.replace("  ", " ")
        id, msisdn, imsi, imei, _, _ = sub.split(" ")

        subscribers[imsi] = {"id": id, "msisdn": msisdn, "imei": imei}
    return subscribers


def get_active_subscribers_imsi():
    with SynchronousCtrlConnection(host, msc_ctrl_port) as conn:
        subscribers = conn.get_value("subscriber-list-active-v1")

    subscribers = subscribers.split(" ")[1].strip()
    subscriber_list = []

    if len(subscribers) > 0:
        # Split on newlines for the payload
        for subscriber in subscribers.split("\n"):
            (imsi, msisdn) = subscriber.split(",")
            subscriber_list.append(imsi)

    return subscriber_list


def get_active_subscribers_msisdn():
    with SynchronousCtrlConnection(host, msc_ctrl_port) as conn:
        subscribers = conn.get_value("subscriber-list-active-v1")

    subscribers = subscribers.split(" ")[1].strip()
    subscriber_list = []

    if len(subscribers) > 0:
        # Split on newlines for the payload
        for subscriber in subscribers.split("\n"):
            (imsi, msisdn) = subscriber.split(",")
            subscriber_list.append(msisdn)

    return subscriber_list


def get_active_subscribers_dict():
    with SynchronousCtrlConnection(host, msc_ctrl_port) as conn:
        subscribers = conn.get_value("subscriber-list-active-v1")

    subscribers = subscribers.split(" ")[1].strip()
    subscriber_dict = {}

    if len(subscribers) > 0:
        # Split on newlines for the payload
        for subscriber in subscribers.split("\n"):
            (imsi, msisdn) = subscriber.split(",")
            subscriber_dict[imsi] = msisdn

    return subscriber_dict


def get_active_subscribers_info():
    subscriber_list = get_active_subscribers_imsi()
    pdp = get_pdp_context()
    hlr_users = get_hlr()
    return [
        {
            "id": hlr_users[sub]["id"],
            "msisdn": hlr_users[sub]["msisdn"],
            "imsi": sub,
            "imei": hlr_users[sub]["imei"],
            "apn": pdp[sub]["apn"] if sub in pdp else "",
            "ipv4": pdp[sub]["ipv4"] if sub in pdp else "",
            "ipv6": pdp[sub]["ipv6"] if sub in pdp else "",
            "ul": pdp[sub]["upload"] if sub in pdp else "",
            "dl": pdp[sub]["download"] if sub in pdp else "",
        }
        for sub in subscriber_list
    ]


def send_sms(source, dest, text):
    client = smpplib.client.Client(host, 2775)
    client.connect()
    client.bind_transceiver(system_id="OSMO-SMPP", password="1234")

    parts, encoding_flag, msg_type_flag = smpplib.gsm.make_parts(text)
    try:
        text.encode("ascii")
        coding = encoding_flag
    except:
        coding = smpplib.consts.SMPP_ENCODING_ISO10646

    logging.info('Sending SMS "%s" to %s' % (text, dest))
    for part in parts:
        pdu = client.send_message(
            msg_type=smpplib.consts.SMPP_MSGTYPE_USERACK,
            source_addr_ton=smpplib.consts.SMPP_TON_ALNUM,
            source_addr_npi=smpplib.consts.SMPP_NPI_ISDN,
            source_addr=source,
            dest_addr_ton=smpplib.consts.SMPP_TON_INTL,
            dest_addr_npi=smpplib.consts.SMPP_NPI_ISDN,
            destination_addr=dest,
            short_message=part,
            data_coding=coding,
            esm_class=msg_type_flag,
            registered_delivery=True,
        )
    logging.debug(pdu.sequence)
    client.unbind()
    client.disconnect()


def send_ussd(msisdn, type, text):
    vty = VTYInteract("OsmoMSC", host, msc_vty_port)
    logging.debug(
        vty.enabled_command(
            f"subscriber msisdn {msisdn} silent-call start any signalling", close=True
        )
    )
    # we need to be sure that connection is established before send ussd
    tries = 10
    while tries:
        out = vty.command(f"show subscriber msisdn {msisdn}")
        if "active-conn" in out:
            break
        tries -= 1
        time.sleep(0.5)
    logging.debug(
        vty.enabled_command(
            f"subscriber msisdn {msisdn} ussd-notify {type} {text}", close=True
        )
    )
    logging.debug(
        vty.enabled_command(f"subscriber msisdn {msisdn} silent-call stop", close=True)
    )


def send_call(caller_extension, extension, voice_file):
    if not caller_extension:
        caller_extension = ""
    if not voice_file:
        voice_file = "tt-monkeys"

    call_data = """Channel: SIP/GSM/{}
MaxRetries: 10
RetryTime: 10
WaitTime: 30
CallerID: {}
Application: Playback
Data: {}""".format(
        extension, caller_extension, voice_file
    )

    call_file = f"/asterisk_outgoing/{''.join(random.choice('0123456789') for _ in range(5))}_{extension}.call"
    with open(call_file, "w") as f:
        f.write(call_data)
        f.close()
