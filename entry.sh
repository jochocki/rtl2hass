#!/bin/sh
rtl_433 -F json | python /scripts/rtl_433_mqtt_hass.py