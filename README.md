# moe-smart-home

A ready-to-use Node-RED setup for home automation. It includes [Node-RED](https://nodered.org/),
MQTT (provided by [Eclipse Mosquitto](https://mosquitto.org/)), Zigbee-Support (provided by [zigbee2mqtt](https://www.zigbee2mqtt.io/)).

We also added Node-RED-Nodes for [HomeKit](https://github.com/NRCHKB/node-red-contrib-homekit-bridged),  [FritzBox](https://github.com/bashgroup/node-red-contrib-fritz), [Tado](https://github.com/mattdavis90/node-red-contrib-tado-client), [Bluetooth-LE-Support](https://github.com/clausbroch/node-red-contrib-noble-bluetooth), [Zigbee2Mqtt-Support](https://flows.nodered.org/node/node-red-contrib-zigbee2mqtt) and a [Dashboard](https://github.com/node-red/node-red-dashboard).

## Requirements

To get this going you need a working [Docker 18.02.0+ setup](https://docs.docker.com/install/) and [docker-compose](https://docs.docker.com/compose/install/).

This setup will run on any  AMD64 or ARM32v7 Linux machine. This includes virtually any PC or a Raspberry Pi 3 or newer. We also build containers for ARM64v8, ARM32v6 but they are untested. If you want to run the containers on macOS, try running `start.sh` as root.

If you want to control Zigbee devices you also will need a Zigbee controller stick. Have a look at [Zigbee2MQTT's documentation](https://www.zigbee2mqtt.io/getting_started/what_do_i_need.html) for that.

## Getting started

* `cd` into the folder containing this repos files

* Run `./start.sh start` to setup the data folder needed to run the containers and start them up.  
*Note: The Zigbee2mqtt container will only start if a [Zigbee-Controller](https://www.zigbee2mqtt.io/information/supported_adapters.html) is connected. Make sure to update the adapter to the newest firmware!*  
**Backup the `./data` folder regularly, as it contains all your data and configuration files**

* When you've got "the hang of it" follow the steps listed in the *Security* section to get a properly secured setup.

### Updating

You should make a backup of all files in the `./data` folder. If you made changes to files outside of `./data` it is imperative to backup those too.

An update via `start.sh update` will pull the latest release of this repository. This will work for most use cases.

If you made changes to files provided in the repository, you'll have to undo those changes and reapply them. If you're familiar with `git` use `git stash` and `git stash apply`. If you want a specially customized version of this repo, think about forking it.

If you manually downloaded the files from the release tab, you'll have to do the update manually. This takes three steps:

* Backup your installation

* Run `docker-compose down --remove-orphans`

* Download the new release and overwrite the files in your installation. Or even better: switch to a cloned repository.

* Run `./start.sh start`

### Configuration

To change configuration of the provided services, either use the corresponding web interfaces or have a look in the `./data` folder. There you'll find all the necessary configurations to modify your setup.

### How to access the services

After starting the containers you'll reach Node-RED [http://docker-host:1880](http://docker-host:1880) and the Zigbee administrative interface at [http://docker-host:1881](http://docker-host:1881). Mosquitto is available on Port 1883 (and 9001 for websockets). You can see more details of the processes output in the container logs with the command `docker-compose logs`.

## `start.sh` options

```plaintext
🏡 setup script
—————————————————————————————
Usage:
start.sh update – to update this copy of the repo
start.sh start – run all containers
start.sh stop – stop all containers
start.sh data – set up the data folder needed for the containers, but run none of them. Useful for personalized setups.
```

## Manual start

* run `./start.sh data` to create the necessary folders
* Use `docker-compose up -d` to start the containers
* If you do not want to start Zigbee2mqtt, add the name of the Node-RED container to the docker-compose command: `docker-compose up -d nodered`. The MQTT container will always be started, because it's a dependency of Node-RED.

### Documentation

[Node-RED documentation](https://nodered.org/docs/)

[Zigbee2MQTT documentation](https://www.zigbee2mqtt.io/)  
(Note: If you use and enjoy the Zigbee service, consider [sponsoring Koen Kanters](https://www.paypal.com/paypalme/koenkk) great work!)

[Mosquitto documentation](https://mosquitto.org/man/mosquitto-8.html)
