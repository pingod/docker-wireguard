# WireGuard in Docker

## Note

-   此镜像需要宿主机内核版本在4.x以上
-   此协议使用UDP协议，而且特征明显，不建议用来FQ
-   如果此容器准备放在K8s中，则需要启用特权容器或者开放部分特权，详细见k8s目录中的编排文件

### Environment Variables

All the variables to this image is optional, which means you don't have to type in any environment variables, and you can have a OpenConnect Server out of the box! However, if you like to config the image the way you like it, here's what you wanna know.

`config_path`, wg的配置文件目录

`wg_port`, wg的服务端口

`wg_ip`, wg服务的ip地址


The default values of the above environment variables:

|   Variable         |             Default     |
|:------------------:|:-----------------------:|
|  **config_path**   |      /etc/wireguard     |
|  **wg_port**       |      8080               |
| **wg_ip**          |      127.0.0.1          |


##  Quick Start

```
docker run \
    --name wireguard \
    -v "$(pwd)":/etc/wireguard \
    -p 55555:8080/udp \
    --cap-add NET_ADMIN \
    --tty --interactive \
    registry.cn-hangzhou.aliyuncs.com/sourcegarden/docker-wg:v1.0
```



