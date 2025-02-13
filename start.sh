#!/bin/bash

function detect_zigbee_device {
	if usb_dev=$(lsusb -d 10c4:); then
		usb_dev_count=$(ls -1 /dev/ttyUSB* 2>/dev/null | wc -l)
		if [ "$usb_dev_count" -gt 1 ]; then
			>&2 echo "There are multiple devices connected, that could be Zigbee USB adaptors. Please check data/zigbee/configuration.yml, if the device is wrong. /dev/ttyUSB0 is used as the default."
			echo "/dev/ttyUSB0"
		fi

		if [ -c /dev/ttyUSB0 ]; then
			echo "/dev/ttyUSB0"
		else
			>&2 echo "I could not find /dev/ttyUSB0. Please check your hardware."
		fi
	elif usb_dev=$(lsusb -d 0451:); then
		usb_dev_count=$(ls -1 /dev/ttyACM* 2>/dev/null | wc -l)
		if [ "$usb_dev_count" -gt 1 ]; then
			>&2 echo "There are multiple devices connected, that could be Zigbee USB adaptors. Please check data/zigbee/configuration.yml, if the device is wrong. /dev/ttyACM0 is used as the default."
			echo "/dev/ttyACM0"
		fi

		if [ -c /dev/ttyACM0 ]; then
			echo "/dev/ttyACM0"
		else
			>&2 echo "I could not find /dev/ttyACM0. Please check your hardware."
		fi

	else
		>&2 echo No Texas Instruments USB device found.
		echo "False"
	fi
}

function create_mosquitto_config {
	cat > data/mqtt/config/mosquitto.conf <<EOF

log_type all

listener 1883
listener 9001
protocol websockets

# Uncomment the following lines and create a passwd file using mosquitto_passwd to enable authentication.
password_file /mosquitto/config/passwd
# Set this to false, to enable authentication
allow_anonymous false
EOF

touch data/mqtt/config/passwd

}

function create_zigbee2mqtt_config {
        configfile='mqtt.cfg'
        if [ -f ${configfile} ]; then
                echo "Reading user config...." >&2

                # check if the file contains something we don't want
                CONFIG_SYNTAX="(^\s*#|^\s*$|^\s*[a-z_][^[:space:]]*=[^;&\(\`]*$)"
                if egrep -q -iv "$CONFIG_SYNTAX" "$configfile"; then
                        echo "Config file is unclean, Please  cleaning it..." >&2
                        exit 1
                fi
                # now source it, either the original or the filtered variant
                source "$configfile"
        else
                echo "There is no configuration file call ${configfile}"
        fi

	cat > data/zigbee/configuration.yaml <<EOF
# Home Assistant integration (MQTT discovery)
homeassistant: true

# allow new devices to join
permit_join: true

# serial config
serial:
  port: /dev/ttyUSB0

# enable frontend
frontend:
  port: 1881
experimental:
  new_api: true

# MQTT settings
mqtt:
  # MQTT base topic for zigbee2mqtt MQTT messages
  base_topic: zigbee2mqtt
  # MQTT server URL
  server: 'mqtt://mqtt'
  # MQTT server authentication, uncomment if required:
  user: $MQTT_USER
  password: $MQTT_PASSWORD

advanced:
  channel: 25
  network_key: GENERATE

EOF

echo 'Disable permit_join in data/zigbee/configuration.yaml or the Zigbee2MQTT webinterface on port 1881, after you have paired all of your devices!'

}

function fix_permissions {
	echo 'Setting the permissions of the configurations in the data folder.'
	sudo chown 1883:1883 data/mqtt
	sudo chown -Rf 1883:1883 data/mqtt/*
	sudo chown 1000:1000 data/nodered
	sudo chown -Rf 1000:1000 data/nodered/*
}

function build_data_structure {
	echo 'Configuration folder ./data is missing. Creating it from scratch.'
	mkdir -p data/mqtt/config
	mkdir -p data/zigbee/
	mkdir -p data/nodered/

	if [ ! -f data/mqtt/config/mosquitto.conf ]; then
		create_mosquitto_config
	fi

	if [ ! -f data/zigbee/configuration.yaml ]; then
		create_zigbee2mqtt_config
	fi

        fix_permissions
}

function check_dependencies {
	if ! [ -x "$(command -v docker-compose)" ]; then
		if ! [ -n "$(docker compose version 2>/dev/null)" ]; then
			echo 'Error: neither docker-compose nor docker compose is installed.' >&2
			exit 1
		fi
	fi

	if ! [ -x "$(command -v git)" ]; then
		echo 'Error: git is not installed.' >&2
		exit 1
	fi
}

function start {

	device=$(detect_zigbee_device)
	if [ $device == "False" ]; then
		echo 'No Zigbee adaptor found. Not starting Zigbee2MQTT.'
		container="nodered mqtt"
	fi

	if [ ! -d data ]; then
		build_data_structure
	fi

	echo 'Starting the containers'
	if [[ $(uname -m) =~ "arm" ]]; then
   		docker compose -f docker-compose.yml -f docker-compose.arm32v7.yml up -d $container
	elif [[ $(uname -m) =~ "aarch" ]]; then
   		docker compose -f docker-compose.yml -f docker-compose.arm32v7.yml up -d $container
	else
		docker compose up -d $container
	fi
}

function stop {
	echo 'Stopping all containers'
	docker compose stop
}

function build {
	echo 'Building docker image'
	cd docker-image
	./docker-make.sh
	cd ..
}

function update {

	if [[ ! -d ".git" ]]
	then
		echo "Manually downloaded version.
Automatic update only works with a cloned Git repository.
Back up your settings and shut down all containers with

docker compose down --remove orphans

Then copy the current version from GitHub to this folder and run

./start.sh start.

Alternatively create a Git clone of the repository."
exit 1
	fi
	echo 'Shutting down all running containers and removing them.'
	docker compose down --remove-orphans
	if [ ! $? -eq 0 ]; then
		echo 'Updating failed. Please check the repository on GitHub.'
	fi
	echo 'Pulling latest release via git.'
	git fetch --tags
	latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
	git checkout $latestTag
	if [ ! $? -eq 0 ]; then
		echo 'Updating failed. Please check the repository on GitHub.'
	fi
	echo 'Pulling docker images.'
	docker compose pull
	if [ ! $? -eq 0 ]; then
		echo 'Updating failed. Please check the repository on GitHub.'
	fi
	start
        fix_permissions
}

check_dependencies

case "$1" in
	"start")
		start
		;;
	"stop")
		stop
		;;
	"update")
		update
		;;
	"build")
		build
		;;
	"data")
		build_data_structure
		;;
	* )
		cat << EOF
setup script
—————————————————————————————
Usage:
start.sh update – update to the latest release version
start.sh start – run all containers
start.sh stop – stop all containers
start.sh build - build docker image
start.sh data – set up the data folder needed for the containers, but run none of them. Useful for personalized setups.

EOF
		;;
esac
