# osmocom network in docker container

for main description and setup guide please read origin/main README.md: https://github.com/godfuzz3r/osmo-nidc/blob/main/README.md
security-assessment oriented branch:
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
