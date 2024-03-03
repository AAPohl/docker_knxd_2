FROM debian:stable as stage1

# prepare
RUN apt-get update \
 && apt-get install -y git-core

# get knxd
RUN git clone -b debian https://github.com/knxd/knxd.git \
 && cd knxd
WORKDIR knxd

# 0 config
RUN set -xe \
 && export LC_ALL=C.UTF-8

# 1 install tools, minimal variant
RUN apt-get install -y --no-install-recommends build-essential \
        devscripts \
        equivs

# 2 auto-install packages required for building knxd
RUN mk-build-deps --install \
        --tool='apt-get --no-install-recommends --yes --allow-unauthenticated' \
        debian/control \
 && rm -f knxd-build-deps_*.deb

# 3 Build. Takes a while.
RUN dpkg-buildpackage -b -uc

FROM debian:stable-slim

COPY --from=stage1 /knxd_*.deb /
COPY --from=stage1 /knxd-tools_*.deb /

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends libev4 libusb-1.0-0 libfmt9 && \
    mkdir -p /pkg


# 4 Install knxd. Have fun.
RUN dpkg -i knxd_*.deb knxd-tools_*.deb

CMD ["/bin/bash"]
