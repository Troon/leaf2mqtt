#!/bin/bash

echo "Starting up..."
cd /root

if [ -z "$MQTTUSER" ]
then
    ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC > cmd.sh
else
    ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC --mqttuser=$MQTTUSER --mqttpass=$MQTTPASS > cmd.sh
fi

chmod +x cmd.sh
echo "Publishing responses..."
./cmd.sh

echo "Starting up MQTT loop..."

VIN=`head -n 1 vin.txt`

if [ -z "$MQTTUSER" ]
then
    EXTRAS=""
else
    EXTRAS="-u \"$MQTTUSER\" -P \"$MQTTPASS\""
fi

while true
do
    mosquitto_sub -h "$MQTTHOST" -t "$MQTTTOPIC/$VIN/set/#" $EXTRAS -v | while read -r topic payload
    do
        echo "Rx: ${topic}: ${payload}"
        if [[ "$topic" == "$MQTTTOPIC/$VIN/set/climate" ]]
        then
            ./leaf_climate.exe --username=$USERNAME --password=$PASSWORD --temperature "${payload}"
        # elif [[ "$topic" == "$MQTTTOPIC/$VIN/set/charge" ]]
        # then
        #     ./leaf_charge.exe --username=$USERNAME --password=$PASSWORD --operation "${payload}"
        fi

        echo "Refreshing..."

        if [ -z "$MQTTUSER" ]
        then
            ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC > cmd.sh
        else
            ./leaf2mqtt.exe --username=$USERNAME --password=$PASSWORD --mqtthost=$MQTTHOST --mqtttopic=$MQTTTOPIC --mqttuser=$MQTTUSER --mqttpass=$MQTTPASS > cmd.sh
        fi

        chmod +x cmd.sh
        echo "Publishing responses after command..."
        ./cmd.sh

    done
done

