

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------
# Step 1: Install base dependencies
# ----------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git wget curl gnupg2 lsb-release software-properties-common \
    build-essential autoconf automake devscripts cmake pkg-config libtool \
    libncurses5-dev libssl-dev libedit-dev libz-dev libsqlite3-dev libcurl4-openssl-dev \
    libpcre3-dev libpcre2-dev libspeex-dev libspeexdsp-dev libtiff5-dev libjpeg-dev libsndfile1-dev \
    libopus-dev libmpg123-dev libavformat-dev libavcodec-dev libswscale-dev \
    libldns-dev liblua5.2-dev libpq-dev libmariadb-dev-compat libmariadb-dev \
    libmemcached-dev libshout3-dev libmp3lame-dev libvpx-dev libyuv-dev \
    libperl-dev libxslt1-dev libxml2-dev uuid-dev yasm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# ----------------------------------------------------------
# Step 2: Build dependencies (spandsp, sofia-sip, libks)
# ----------------------------------------------------------
RUN git clone https://github.com/freeswitch/spandsp.git && cd spandsp && ./bootstrap.sh && ./configure --prefix=/usr/local && make -j$(nproc) && make install && ldconfig

RUN git clone https://github.com/freeswitch/sofia-sip.git && cd sofia-sip && ./bootstrap.sh && ./configure --prefix=/usr/local && make -j$(nproc) && make install && ldconfig

RUN git clone https://github.com/signalwire/libks.git && cd libks && cmake . && make && make install && ldconfig

# ----------------------------------------------------------
# Step 3: Build FreeSWITCH (disable SignalWire modules)
# ----------------------------------------------------------
RUN git clone https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    ./bootstrap.sh -j && \
    sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf && \
    sed -i 's|endpoints/mod_verto|#endpoints/mod_verto|g' modules.conf && \
    ./configure -C --disable-dependency-tracking && \
    make -j$(nproc) && make install && make sounds-install moh-install

# ----------------------------------------------------------
# Step 4: Setup runtime directories and permissions
# ----------------------------------------------------------
RUN ln -s /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch && \
    mkdir -p /usr/local/freeswitch/{log,run,recordings,conf} && \
    chmod -R 777 /usr/local/freeswitch

EXPOSE 6060/udp 6060/tcp 8022/tcp 16384-32768/udp

# ----------------------------------------------------------
# Step 5: Run Freeswitch in foreground (non-daemon)
# ----------------------------------------------------------
CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-nf", "-u", "root", "-g", "root"]
