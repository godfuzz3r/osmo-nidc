import socket
from osmopy.osmo_ipa import Ctrl


class SynchronousCtrlConnection(object):
    """A simple osmo-ctrl connection receiver

    This class is not multithread safe, and is not save to use with traps
    enabled since its socket message parsing is very simplistic and could be
    thrown off by partial messages received concurrently over stream socket.
    """

    def __init__(self, host, port):
        self._host = host
        self._port = port
        self._ctrl = Ctrl()

    def __enter__(self):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.setblocking(True)
        self._sock.settimeout(5.0)  # Timeout in seconds
        self._sock.connect((self._host, self._port))
        return self

    def __exit__(self, type, value, traceback):
        self._sock.close()

    def get_value(self, key):
        (msg_id, payload) = self._ctrl.cmd(key, val=None)
        self._sock.send(payload)

        while True:
            return_payload = self._sock.recv(16384)
            return self._parse_for_id(return_payload, msg_id)

    def _parse_for_id(self, payload, sought_id):
        while len(payload) > 0:
            (message_bytes, payload_remaining) = self._ctrl.split_combined(payload)
            (msg_id, message, _) = self._ctrl.parse(message_bytes)
            msg_id = int(msg_id)
            if msg_id == sought_id:
                return message
            payload = payload_remaining

        raise "No response with id {} found".format(sought_id)
