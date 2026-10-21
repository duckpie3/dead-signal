#!/bin/sh
# Prints the Open-Meteo forecast as JSON.  usage: weather.sh LAT LON celsius|fahrenheit
unit=${3:-celsius}
wind=kmh
[ "$unit" = fahrenheit ] && wind=mph
curl -fsS --max-time 15 \
    "https://api.open-meteo.com/v1/forecast?latitude=$1&longitude=$2&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day&hourly=temperature_2m,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=4&timezone=auto&temperature_unit=$unit&wind_speed_unit=$wind"
