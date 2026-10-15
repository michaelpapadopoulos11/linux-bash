#!/bin/bash

DRIVE="/dev/sdb"
#^^ change the location of the disk to check other disk drives health#

if [ ! -e "$DRIVE" ]; then
    echo "could not find the drive : $DRIVE."
    exit 1
fi
echo ""
echo "=================================================="
echo "          CLI DISK HEALTH READER ($DRIVE)         "
echo "=================================================="

# Extract Basic Info Section using smartctl -i
MODEL=$(sudo smartctl -i "$DRIVE" | grep "Device Model:" | awk -F: '{print $2}' | xargs)
SERIAL=$(sudo smartctl -i "$DRIVE" | grep "Serial Number:" | awk -F: '{print $2}' | xargs)
CAPACITY=$(sudo smartctl -i "$DRIVE" | grep "User Capacity:" | awk -F: '{print $2}' | xargs)
FORM_FACTOR=$(sudo smartctl -i "$DRIVE" | grep "Form Factor:" | awk -F: '{print $2}' | xargs)
ROTATION=$(sudo smartctl -i "$DRIVE" | grep "Rotation Rate:" | awk -F: '{print $2}' | xargs)
FIRMWARE=$(sudo smartctl -i "$DRIVE" | grep "Firmware Version:" | awk -F: '{print $2}' | xargs)

echo ""
echo "   Make / Model:   ${MODEL:-N/A}"
echo "   Serial Number:  ${SERIAL:-N/A}"
echo "   Firmware:       ${FIRMWARE:-N/A}"
echo "   Size / Capacity:${CAPACITY:-N/A}"
echo "   Form Factor:    ${FORM_FACTOR:-N/A}"
echo "   Rotation Rate:  ${ROTATION:-N/A}"
echo ""
echo "--------------------------------------------------"

# Overall SMART Health Status
HEALTH=$(sudo smartctl -H "$DRIVE" | grep "SMART overall-health" | awk -F: '{print $2}' | xargs)
echo " SMART Health:   ${HEALTH:-UNKNOWN}"

# Helper function to get RAW value of a specific SMART attribute ID
get_attrib() {
    sudo smartctl -A "$DRIVE" | awk -v id="$1" '$1 == id {print $10}'
}

# Key Attributes
REALLOCATED=$(get_attrib 5)
PENDING=$(get_attrib 197)
UNCORRECTABLE=$(get_attrib 198)
REPORTED_UNCORR=$(get_attrib 187)
POWER_HOURS=$(get_attrib 9)
POWER_CYCLES=$(get_attrib 12)
LOAD_CYCLES=$(get_attrib 193)
UDMA_ERRORS=$(get_attrib 199)



# Extract temperature cleanly
TEMP=$(sudo smartctl -A "$DRIVE" | grep -E "Temperature_Celsius|Airflow_Temperature_Cel" | head -n 1 | awk '{print $10}')

echo "--------------------------------------------------"
echo ""
echo " Critical Health Attributes:"
echo "   Reallocated Sectors (ID 5):   ${REALLOCATED:-0}"
echo "   Pending Sectors (ID 197):     ${PENDING:-0}"
echo "   Offline Uncorrectable (198):  ${UNCORRECTABLE:-0}"
echo "   Reported Uncorrectable(187):  ${REPORTED_UNCORR:-0}"
echo "   UDMA CRC Errors (ID 199):     ${UDMA_ERRORS:-0}"
echo "--------------------------------------------------"
echo " Usage & Environment Stats:"
echo "   Power-On Hours:               ${POWER_HOURS:-N/A}"
echo "   Power Cycles (Reboots):       ${POWER_CYCLES:-N/A}"
echo "   Load Cycles (Head Parkings):  ${LOAD_CYCLES:-N/A}"
echo "   Temperature:                  ${TEMP:-N/A} °C"
echo ""
echo "=================================================="


# Quick Condition Evaluation
if [ "$HEALTH" = "PASSED" ] && [ "${REALLOCATED:-0}" -eq 0 ] && [ "${PENDING:-0}" -eq 0 ] && [ "${REPORTED_UNCORR:-0}" -eq 0 ]; then
    echo " Condition:      GOOD (No critical errors)"
else
    echo " Condition:      BAD / WARNING"
fi
echo "=================================================="
echo ""
