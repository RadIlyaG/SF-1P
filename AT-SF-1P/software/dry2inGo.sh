#!/bin/bash
DC_IN1=422
DC_IN2=423
DC_IN1_DIR=/sys/class/gpio/gpio422
DC_IN2_DIR=/sys/class/gpio/gpio423


#echo "Configuring GPIO"


#check if the gpio is already exported
if [ ! -e "$DC_IN1_DIR" ]
then
            echo "Exporting DC_IN1"
            echo $DC_IN1 > /sys/class/gpio/export
else
            echo "DC_IN1 already exported"
fi

if [ ! -e "$DC_IN2_DIR" ]
then
            echo "Exporting DC_IN2"
            echo $DC_IN2 > /sys/class/gpio/export
else
            echo "DC_IN2 already exported"
fi


#echo "Set GPIOs as output and input"


echo in > $DC_IN1_DIR/direction
echo in > $DC_IN2_DIR/direction

# Read the current GPIO pin values
value1=$(cat /sys/class/gpio/gpio$DC_IN1/value)
value2=$(cat /sys/class/gpio/gpio$DC_IN2/value)
# Print the GPIO pin values
echo "DC_IN_1:$value1"
echo "DC_IN_2:$value2"

