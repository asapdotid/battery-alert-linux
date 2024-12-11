#!/usr/bin/env bash

# Default variables, optional for customization
# ALERT_SOUND=true
# ALERT_FULL=true
# ALERT_EMPTY=true
# ALERT_EMPTY_TRHESHOLD=30

# The configuration below is not customizable by the user

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

# Checks if ac_power is ON and battery is full
battery_full=$(acpi -b | grep -c "Full")

# when the battery is charging and it gets charged up to 100%
# if ac_power is ON and battery_level is 100
if [[ "${ALERT_FULL?}" ]]; then
    if [[ "${ac_power}" -eq 1 && "${battery_level}" -eq 100 ]] || [[ "${battery_full}" -eq 1 ]]; then
        # Send a notification that appears for 120000 ms (2 min)
        notify-send -t 120000 -u normal "Battery Full" "Level: ${battery_level}%, please remove the charger"
        if [ "${ALERT_SOUND?}" ]; then
            if command -v paplay >&2; then
                exec paplay --volume=52000 /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
            else
                exec pw-play --volume=0.5 /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
            fi
        else
            exec espeak "Battrey is full, Please Remove the charger" - s 140
        fi
    fi
fi

# when the battery is not charging
# if ac_power is OFF and battery_level is less than or equal to 92
if [[ "${ALERT_EMPTY?}" ]]; then
    if [[ "${ac_power}" -eq 0 && "${battery_level}" -le ${ALERT_EMPTY_TRHESHOLD?} ]]; then
        # Send a notification that appears for 120000 ms (2 min)
        notify-send -t 120000 -u critical "Battery Low" "Level: ${battery_level}%, please connect the charger"
        if [ "${ALERT_SOUND?}" ]; then
            if command -v paplay >&2; then
                exec paplay --volume=52000 /usr/share/sounds/freedesktop/stereo/suspend-error.oga
            else
                exec pw-play --volume=0.5 /usr/share/sounds/freedesktop/stereo/suspend-error.oga
            fi
        else
            exec espeak "Battrey is low, Please connect the charger" - s 140
        fi
    fi
fi
