ARG NODE_VERSION=22
ARG OS=alpine

#### Stage BASE ########################################################################################################
FROM node:${NODE_VERSION}-${OS} AS base

# Copy scripts
COPY scripts/*.sh /tmp/

# Install tools, create Node-RED app and data dir, add user and set rights
RUN set -ex && \
    apk add --no-cache \
    bash \
    tzdata \
    iputils \
    curl \
    nano \
    git \
    openssl \
    openssh-client \
    su-exec \
    avahi \
    avahi-compat-libdns_sd \
#    dbus \
    ffmpeg \
    libcap-utils \
    bluez && \
#    dbus-uuidgen --ensure && \
#    dbus-daemon --system && \
    mkdir -p /usr/src/node-red /data && \
    deluser --remove-home node && \
    adduser -h /usr/src/node-red -D -H node-red -u 1000 && \
    chown -R node-red:root /data && chmod -R g+rwX /data && \ 
    chown -R node-red:root /usr/src/node-red && chmod -R g+rwX /usr/src/node-red 

# Set work directory
WORKDIR /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY package.json .

#### Stage BUILD #######################################################################################################
FROM base AS build

# Install Build tools
RUN apk add --no-cache --virtual buildtools build-base linux-headers udev eudev-dev avahi-dev libusb-dev libc-dev python3 && \
    npx npm-check-updates -u && \
    npm install --unsafe-perm --no-update-notifier --only=production --no-optional && \
    /tmp/remove_native_gpio.sh && \
    npm dedupe && \
    npm cache clean --force && \
    npm prune --production && \
    apk del buildtools && \
    cp -R node_modules prod_node_modules


#### Stage RELEASE #####################################################################################################
FROM base AS RELEASE
USER root 
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG ARCH
ARG NODE_RED_VERSION=latest
ARG TAG_SUFFIX=default

LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile="Dockerfile" \
    org.label-schema.license="Apache-2.0" \
    org.label-schema.name="Node-RED for moe-smart-home" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="low code graphical smart home programming environment" \
    org.label-schema.url="https://github.com/moeb98/moe-smart-home" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/moeb98/moe-smart-home" \
    org.label-schema.arch=${ARCH} \
    authors="Dave Conway-Jones, Nick O'Leary, James Thomas, Raymond Mouthaan, Merlin Schumacher, Jan Mahn, Andrijan Möcker, Anton Golubev, J. Völker, GnafGnaf, Mario Eberlein" \
    org.opencontainers.image.source=https://github.com/moeb98/moe-smart-home

COPY --from=build /usr/src/node-red/prod_node_modules ./node_modules
COPY entrypoint.sh /usr/src/node-red/entrypoint.sh

# Chown, install devtools & Clean up
RUN rm -r /tmp/* && \
    setcap 'cap_net_raw+eip' `which l2ping` && \
    setcap 'cap_net_raw+eip' `which node`

# Env variables
ENV NODE_RED_VERSION=$NODE_RED_VERSION \
    NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    FLOWS=flows.json

# ENV NODE_RED_ENABLE_SAFE_MODE=true    # Uncomment to enable safe start mode (flows not running)
# Enable GitHub version control with Node Red Projects 
ENV NODE_RED_ENABLE_PROJECTS=true     

# User configuration directory volume
VOLUME ["/data"]

# Expose the listening port of node-red
EXPOSE 1880

# Add a healthcheck (default every 30 secs)
HEALTHCHECK CMD curl http://localhost:1880/ || exit 1

CMD ["/bin/sh", "/usr/src/node-red/entrypoint.sh" ]
