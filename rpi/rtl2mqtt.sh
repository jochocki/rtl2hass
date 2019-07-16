#!/bin/bash

# A simple script that will receive events from a RTL433 SDR

# Author: Marco Verleun <marco@marcoach.nl>
# Version 2.0: Adapted for the new output format of rtl_433

# Remove hash on next line for debugging
#set -x

export LANG=C
PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

#
# Start the listener and enter an endless loop
#
rtl_433 -R 40 -q  -F json|  while read line
do
	sensorId=$(echo $line | jq -r '.id')
	temperature=$(echo $line | jq -r '.temperature_C')
	humidity=$(echo $line | jq -r '.humidity')
        mosquitto_pub -h $MQTT_HOST -d -t "home/sensors/$sensorId" -m "$line"  
        mosquitto_pub -h $MQTT_HOST -d -t "home/sensors/$sensorId/temperature" -m "$temperature"       
        mosquitto_pub -h $MQTT_HOST -d -t "home/sensors/$sensorId/humidity" -m "$humidity"
done
