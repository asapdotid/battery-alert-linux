#!/usr/bin/env bash

# Default variables, optional for customization
# ALERT_SOUND=true
# ALERT_FULL=true
# ALERT_EMPTY=true
# ALERT_EMPTY_TRHESHOLD=30

# The configuration below is not customizable by the user

if command -v upower &> /dev/null; then
    # upower -i produces output as
    # Show information about the given device
    # Enumerate the object paths of all devices on the system
    # So we get percentage: 41%
    # Now we'll replace the % sign by "", so 41% will
    # be changed to 41 now.
    battery_level=$(upower -i "$(upower -e battery | head -n 1)" | grep percentage | awk '{print $2}' | sed 's/%//')

    # If the charger is plugged in, upower shows "charging"
    # and if it's not plugged in, it shows "discharging".
    # if upower -i shows charging, "grep state" will return "charging"
    # else it will return "discharging"
    ac_power=$(upower -i "$(upower -e battery | head -n 1)" | grep state | awk '{print $2}')

    # Checks if ac_power is ON and battery is full
    check_charging_full=$(upower -i "$(upower -e battery | head -n 1)" | grep state | awk '{print $2}' | grep -c "fully-charged")

    # when the battery is not charging
    # if ac_power is OFF and battery_level is less than or equal to 30
    if [[ "${ALERT_EMPTY?}" ]]; then
        if [[ "${ac_power}" != "charging" && "${battery_level}" -le ${ALERT_EMPTY_TRHESHOLD?} ]]; then
            # Send a notification that appears for 120000 ms (2 min)
            notify-send -t 120000 -u critical "Battery Low" "Level: ${battery_level}%, please connect the charger"
            if [ "${ALERT_SOUND?}" ]; then
                if command -v paplay >&2; then
                    exec paplay --volume=32000 /usr/share/sounds/freedesktop/stereo/suspend-error.oga
                elif command -v pw-play >&2; then
                    exec pw-play --volume=0.3 /usr/share/sounds/freedesktop/stereo/suspend-error.oga
                fi
            else
                if command -v espeak >&2; then
                    exec espeak "Battrey is low, Please connect the charger" - s 140
                fi
            fi
        fi
    fi

    # when the battery is charging and it gets charged up to 100%
    # if ac_power is ON and battery_level is 100
    if [[ "${ALERT_FULL?}" ]]; then
        if [[ "${check_charging_full}" -eq 1 && "${battery_level}" -eq 100 ]]; then
            # Send a notification that appears for 120000 ms (2 min)
            notify-send -t 120000 -u normal "Battery Full" "Level: ${battery_level}%, please remove the charger"
            if [ "${ALERT_SOUND?}" ]; then
                if command -v paplay >&2; then
                    exec paplay --volume=32000 /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
                elif command -v pw-play >&2; then
                    exec pw-play --volume=0.3 /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
                fi
            else
                if command -v espeak >&2; then
                    exec espeak "Battrey is full, Please Remove the charger" - s 140
                fi
            fi
        fi
    fi
elif command -v acpi &> /dev/null; then
    # acpi -b produces output as
    # Battery 0: Discharging, 41%, 01:08:14 remaining
    # To get the battery percentage only we'll cut the
    # second value which ends at ", ". So we get 41%
    # Now we'll replace the % sign by "", so 41% will
    # be changed to 41 now.
    battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

    # If the charger is plugged in, acpi shows "charging"
    # and if it's not plugged in, it shows "discharging".
    # if acpi -b shows charging, "grep -c" will return 1
    # else it will return 0
    ac_power=$(acpi -b | grep -c "Charging")

    # acpi get Battrey charging and full
    check_charging_full=$(acpi -b | grep -c "Charging, Full")

    # when the battery is not charging
    # if ac_power is OFF and battery_level is less than or equal to 92
    if [[ "${ALERT_EMPTY?}" ]]; then
        if [[ "${ac_power}" -eq 0 && "${battery_level}" -le ${ALERT_EMPTY_TRHESHOLD?} ]]; then
            # Send a notification that appears for 120000 ms (2 min)
            notify-send -t 120000 -u critical "Battery Low" "Level: ${battery_level}%, please connect the charger"
            if [ "${ALERT_SOUND?}" ]; then
                if command -v paplay >&2; then
                    exec paplay --volume=32000 /usr/share/sounds/freedesktop/stereo/suspend-error.oga
                elif command -v pw-play >&2; then
                    exec pw-play --volume=0.3 /usr/share/sounds/freedesktop/stereo/suspend-error.oga
                fi
            else
                if command -v espeak >&2; then
                    exec espeak "Battrey is low, Please connect the charger" - s 140
                fi
            fi
        fi
    fi

    # when the battery is charging and it gets charged up to 100%
    # if ac_power is ON and battery_level is 100
    if [[ "${ALERT_FULL?}" ]]; then
        if [[ "${check_charging_full}" -eq 1 && "${battery_level}" -eq 100 ]]; then
            # Send a notification that appears for 120000 ms (2 min)
            notify-send -t 120000 -u normal "Battery Full" "Level: ${battery_level}%, please remove the charger"
            if [ "${ALERT_SOUND?}" ]; then
                if command -v paplay >&2; then
                    exec paplay --volume=32000 /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
                elif command -v pw-play >&2; then
                    exec pw-play --volume=0.3 /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
                fi
            else
                if command -v espeak >&2; then
                    exec espeak "Battrey is full, Please Remove the charger" - s 140
                fi
            fi
        fi
    fi
else
    echo "upower or acpi is not installed"
fi
