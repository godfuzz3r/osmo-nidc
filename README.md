# osmocom network in docker container

devuce pentest oriented branch:
- network_mode=host
- http-proxying (invisible for devices)

# proxy setup

to pass devices trafic trough proxy, change `proxy-enabled` option to `true` in `./configs/config.yml` (enabled by default):
```
...
egprs:
  proxy-enabled: true
  proxy-url: http://127.0.0.1:8080
...
```

this will pass all traffic from `apn0` interface through chain redsocks -> gost socks5 -> your proxy (e.g burp suite), proxy-url may be any kind of proxy supported by gost (see https://github.com/ginuerzh/gost/blob/master/README_en.md)

this option will disable routing setup since it is not required


## troubleshooting

#### I have `Error reading from server - read (104: Connection reset by peer)` error when building containers

- probably network/firewall issues, restart building process may help

#### my device not passed to the container/got error `Permission denied` on device

- sometimes devices may be not properly "passed" to container. Stop container, reconnect device and start container again may help. (I actually don't know how to solve this problem. If now how to solve this - don't hesitate to create pull requests!)

#### apn0 interface don't appear at start

- probably old docker version. Try update docker or add interface outside of container manually (before starting container): `sudo ip tuntap add dev apn0 mode tun`