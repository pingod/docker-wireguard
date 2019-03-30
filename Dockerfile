# Usage:
# 此镜像需要宿主机内核版本在4.x以上才可使用
# This uses a custom installs a kernel module hence the mounts

# docker run --rm -it \
# 	--name wireguard \
# 	-v /lib/modules:/lib/modules \
# 	r.j3ss.co/wireguard:install

FROM alpine:latest

RUN apk add --no-cache \
	build-base \
	ca-certificates \
	elfutils-libelf \
	libelf-dev \
	libmnl-dev \
    libmnl \
    bash \
    wget \
    curl \
    openresolv \
    iptables




# https://git.zx2c4.com/WireGuard/refs/
ENV WIREGUARD_VERSION 0.0.20190227
ENV WG_QUICK_URL https://git.zx2c4.com/WireGuard/plain/src/tools/wg-quick/linux.bash



RUN set -x \
	&& sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
	&& apk add --no-cache --virtual .build-deps \
		git \
	&& git clone --depth 1 --branch "${WIREGUARD_VERSION}" https://git.zx2c4.com/WireGuard.git /wireguard \
	&& ( \
		cd /wireguard/src \
		&& make tools \
		&& make -C tools install \
		&& make -C tools clean \
	) \
	&& apk del .build-deps

RUN wget -O /bin/wg-quick $WG_QUICK_URL \
    && chmod +x /bin/wg-quick

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["wg-quick", "up", "wg0"]

