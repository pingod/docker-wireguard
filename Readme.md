# WireGuard in Docker

## Note

-   a host with WireGuard support in the kernel is needed
-   a `wg-quick` style config file needs to be mounted at
    `/etc/wireguard/wg0.conf`
-   此协议使用UDP协议，而且特征明显，不建议用来FQ
    felixfischer/wireguard:latest
```


#Quick Start

```
docker run \
    --name wireguard \
    -v "$(pwd)":/etc/wireguard \
    -p 55555:8080/udp \
    --cap-add NET_ADMIN \
    --tty --interactive \
    registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-wg:v1.0
```