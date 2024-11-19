#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

    if [ ! -x "$(which notify-send)" ] && [ ! -x "$(which paplay)" ] && [ ! -x "$(which espeak)" ]; then
        # shellcheck disable=SC2016
        asapbattery_echo >&2 'Error: Dependencies not met. Please install notify-send, paplay and espeak.'
        exit 1
    fi

    battery_alert_has() {
        type "$1" >/dev/null 2>&1
    }

    battery_alert_echo() {
        command printf %s\\n "$*" 2>/dev/null
    }

    battery_alert_grep() {
        GREP_OPTIONS='' command grep "$@"
    }

    battery_alert_default_install_dir() {
        [ -z "${XDG_DATA_HOME-}" ] && printf %s "${XDG_CONFIG_HOME}/battery-alert" || printf %s "${XDG_DATA_HOME}/battery-alert"
    }

    battery_alert_install_dir() {
        if [ -n "$BATTERY_ALERT_DIR" ]; then
            printf %s "${BATTERY_ALERT_DIR}"
        else
            battery_alert_default_install_dir
        fi
    }

    battery_alert_latest_version() {
        battery_alert_echo "main"
    }

    battery_alert_download() {
        if battery_alert_has "curl"; then
            curl --fail --compressed -q "$@"
        elif battery_alert_has "wget"; then
            # Emulate curl with wget
            ARGS=$(battery_alert_echo "$@" | command sed -e 's/--progress-bar /--progress=bar /' \
                -e 's/--compressed //' \
                -e 's/--fail //' \
                -e 's/-L //' \
                -e 's/-I /--server-response /' \
                -e 's/-s /-q /' \
                -e 's/-sS /-nv /' \
                -e 's/-o /-O /' \
                -e 's/-C - /-c /')
            # shellcheck disable=SC2086
            eval wget $ARGS
        fi
    }

    install_battery_alert_from_git() {
        local INSTALL_DIR
        INSTALL_DIR="$(battery_alert_install_dir)"
        local BATTERY_ALERT_VERSION
        BATTERY_ALERT_VERSION="${BATTERY_ALERT_INSTALL_VERSION:-$(battery_alert_latest_version)}"
        local BATTERY_ALERT_SOURCE_URL
        BATTERY_ALERT_SOURCE_URL="https://github.com/asapdotid/battery-alert-linux.git"
        if [ -n "${BATTERY_ALERT_VERSION:-}" ]; then
            # Check if version is an existing ref
            if command git ls-remote "$BATTERY_ALERT_SOURCE_URL" "$BATTERY_ALERT_VERSION" | battery_alert_grep -q "$BATTERY_ALERT_VERSION"; then
                :
            # Check if version is an existing changeset
            elif ! battery_alert_download -o /dev/null "$BATTERY_ALERT_SOURCE_URL"; then
                battery_alert_echo >&2 "Failed to find '$BATTERY_ALERT_VERSION' version."
                exit 1
            fi
        fi

        local fetch_error
        if [ -d "$INSTALL_DIR/.git" ]; then
            # Updating repo
            battery_alert_echo "=> battey alert is already installed in $INSTALL_DIR, trying to update using git"
            command printf '\r=> '
            fetch_error="Failed to update battey alert with $BATTERY_ALERT_VERSION, run 'git fetch' in $INSTALL_DIR yourself."
        else
            fetch_error="Failed to fetch origin with $BATTERY_ALERT_VERSION. Please report this!"
            battery_alert_echo "=> Downloading battey alert from git to '$INSTALL_DIR'"
            command printf '\r=> '
            mkdir -p "${INSTALL_DIR}"
            if [ "$(ls -A "${INSTALL_DIR}")" ]; then
                # Initializing repo
                command git init "${INSTALL_DIR}" || {
                    battery_alert_echo >&2 'Failed to initialize battey alert repo. Please report this!'
                    exit 2
                }
                command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$BATTERY_ALERT_SOURCE_URL" 2>/dev/null ||
                    command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$BATTERY_ALERT_SOURCE_URL" || {
                    battery_alert_echo >&2 'Failed to add remote "origin" (or set the URL). Please report this!'
                    exit 2
                }
            else
                # Cloning repo
                command git clone "$BATTERY_ALERT_SOURCE_URL" --depth=1 "${INSTALL_DIR}" || {
                    battery_alert_echo >&2 'Failed to clone asapsahell repo. Please report this!'
                    exit 2
                }
            fi
        fi

        # Try to fetch tag
        if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin tag "$BATTERY_ALERT_VERSION" --depth=1 2>/dev/null; then
            :
        # Fetch given version
        elif ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin "$BATTERY_ALERT_VERSION" --depth=1; then
            battery_alert_echo >&2 "$fetch_error"
            exit 1
        fi

        command git -c advice.detachedHead=false --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet FETCH_HEAD || {
            battery_alert_echo >&2 "Failed to checkout the given version $BATTERY_ALERT_VERSION. Please report this!"
            exit 2
        }

        if [ -n "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/main)" ]; then
            if command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
                command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D main >/dev/null 2>&1
            else
                battery_alert_echo >&2 "Your version of git is out of date. Please update it!"
                command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D main >/dev/null 2>&1
            fi
        fi

        battery_alert_echo "=> Compressing and cleaning up git repository"
        if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
            battery_alert_echo >&2 "Your version of git is out of date. Please update it!"
        fi
        if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now; then
            battery_alert_echo >&2 "Your version of git is out of date. Please update it!"
        fi
        return
    }

    battery_alert_input_battery_full() {
        local alert_full
        PS3="Please select enable full battery alert: "
        select opt in Yes No; do
            case $opt in
            Yes)
                alert_full=true
                break
                ;;
            No)
                alert_full=false
                break
                ;;
            *)
                echo "invalid option $REPLY"
                ;;
            esac
        done
        echo ${alert_full}
    }

    battery_alert_input_battery_empty() {
        local alert_empty
        PS3="Please select enable empty battery alert: "
        select opt in Yes No; do
            case $opt in
            Yes)
                alert_empty=true
                break
                ;;
            No)
                alert_empty=false
                break
                ;;
            *)
                echo "invalid option $REPLY"
                ;;
            esac
        done
        echo ${alert_empty}
    }

    battery_alert_input_battery_empty_threshold() {
        local alert_empty_threshold
        PS3="Please select empty battery threshold: "
        select opt in 40 35 30 25 20; do
            case $opt in
            40)
                alert_empty_threshold=40
                break
                ;;
            35)
                alert_empty_threshold=35
                break
                ;;
            30)
                alert_empty_threshold=30
                break
                ;;
            25)
                alert_empty_threshold=25
                break
                ;;
            20)
                alert_empty_threshold=20
                break
                ;;
            *)
                echo "invalid option $REPLY"
                ;;
            esac
        done
        echo ${alert_empty_threshold}
    }

    battery_alert_input_sound() {
        local alert_sound
        PS3="Please select enable sound alert: "
        select opt in Yes No; do
            case $opt in
            Yes)
                alert_sound=true
                break
                ;;
            No)
                alert_sound=false
                break
                ;;
            *)
                echo "invalid option $REPLY"
                ;;
            esac
        done
        echo ${alert_sound}
    }

    set_battery_alert_config() {
        local INSTALL_DIR
        INSTALL_DIR="$(battery_alert_install_dir)"
        local alert_full
        alert_full="$(battery_alert_input_battery_full)"
        local alert_empty
        alert_empty="$(battery_alert_input_battery_empty)"
        local alert_empty_threshold
        alert_empty_threshold="$(battery_alert_input_battery_empty_threshold)"
        local alert_sound
        alert_sound="$(battery_alert_input_sound)"

        sed -e 's/^ALERT_FULL=true/ALERT_FULL='"${alert_full}"'/g' \
            -e 's/^ALERT_EMPTY=true/ALERT_EMPTY='"${alert_empty}"'/g' \
            -e 's/^ALERT_EMPTY_TRHESHOLD=[0-9]\+/ALERT_EMPTY_TRHESHOLD='"${alert_empty_threshold}"'/g' \
            -e 's/^ALERT_SOUND=true/ALERT_SOUND='"${alert_sound}"'/g' \
            "${INSTALL_DIR}/battery-alert.tpl.sh" | tee "${INSTALL_DIR}/battery-alert.sh" | bash

        battery_alert_echo >&2 "=> Set Notification config file: ${INSTALL_DIR}/battery-alert.sh"
    }

    battery_alert_set_executable_file() {
        local INSTALL_DIR
        INSTALL_DIR="$(battery_alert_install_dir)"
        chmod +x "${INSTALL_DIR}/battery-alert.sh"
        battery_alert_echo >&2 "=> Set executable file: ${INSTALL_DIR}/battery-alert.sh"
    }

    battery_alert_set_user_service_and_timer() {
        local INSTALL_DIR
        INSTALL_DIR="$(battery_alert_install_dir)"
        local SYSTEM_USER_DIR
        SYSTEM_USER_DIR="${XDG_CONFIG_HOME}/systemd/user"
        [ -d "$SYSTEM_USER_DIR" ] || mkdir -p "$SYSTEM_USER_DIR"

        # Set user service
        cat <<EOF >"${SYSTEM_USER_DIR}/battery-alert.service"
Unit]
Description=Desktop alert warning of low/full battery status

[Service]
Type=oneshot
ExecStart=${INSTALL_DIR}/battery-alert.sh

[Install]
WantedBy=graphical.target
EOF
        battery_alert_echo >&2 "=> Set user service: ${SYSTEM_USER_DIR}/battery-alert.service"

        # Set timer
        cat <<'EOF' >"${SYSTEM_USER_DIR}/battery-alert.timer"
[Unit]
Description=Check battery status every few minutes to warn the user in case of low/full battery
Requires=battery-alert.service

# Define when and how the timer activates
[Timer]
# Start 1 minute after boot...
OnBootSec=1m
# ...and again every 3 minutes after 'battery-battery.service' runs
OnUnitActiveSec=3m

[Install]
WantedBy=timers.target
EOF

        battery_alert_echo >&2 "=> Set user timer: ${SYSTEM_USER_DIR}/battery-alert.timer"
    }

    enable_user_service_and_timer() {
        local INSTALL_DIR
        INSTALL_DIR="$(battery_alert_install_dir)"
        local SYSTEMD_USER_DIR
        SYSTEMD_USER_DIR="${XDG_CONFIG_HOME}/systemd/user"
        if ! [ -f "${INSTALL_DIR}/battery-alert.sh" ] || ! [ -f "${SYSTEMD_USER_DIR}/battery-alert.service" ] || ! [ -f "${SYSTEMD_USER_DIR}/battery-alert.timer" ]; then
            battery_alert_echo >&2 "You need to install battery-alert first."
            exit 1
        fi
        systemctl --user daemon-reload
        systemctl --user enable --now battery-alert.timer
        battery_alert_echo >&2 "=> Enable user service and timer"
    }

    battery_alert_do_install() {
        if [ -n "${BATTERY_ALERT_DIR-}" ] && ! [ -d "${BATTERY_ALERT_DIR}" ]; then
            if [ -e "${BATTERY_ALERT_DIR}" ]; then
                battery_alert_echo >&2 "File \"${BATTERY_ALERT_DIR}\" has the same name as installation directory."
                exit 1
            fi

            if [ "${BATTERY_ALERT_DIR}" = "$(battery_alert_default_install_dir)" ]; then
                mkdir "${BATTERY_ALERT_DIR}"
            else
                battery_alert_echo >&2 "You have \$BATTERY_ALERT_DIR set to \"${BATTERY_ALERT_DIR}\", but that directory does not exist."
                exit 1
            fi
        fi

        if ! battery_alert_has git; then
            battery_alert_echo >&2 "You need git to install linux-battery-alert."
            exit 1
        fi
        install_battery_alert_from_git
        battery_alert_echo
        battery_alert_echo "=> Set battery alert config"
        battery_alert_echo
        set_battery_alert_config
        battery_alert_set_executable_file
        battery_alert_set_user_service_and_timer
        enable_user_service_and_timer
        battery_alert_echo
        battery_alert_reset
        battery_alert_echo "=> Done!"
        battery_alert_echo "=> Checks your battery alert timer and service (systemctl --user list-timers)"
    }

    battery_alert_reset() {
        unset -f battery_alert_has battery_alert_install_dir battery_alert_latest_version \
            battery_alert_download install_battery_alert_from_git battery_alert_do_install \
            battery_alert_default_install_dir battery_alert_grep battery_alert_reset \
            set_battery_alert_config battery_alert_set_executable_file \
            battery_alert_input_battery_full battery_alert_input_battery_empty \
            battery_alert_input_battery_empty_threshold battery_alert_input_sound \
            battery_alert_set_user_service_and_timer enable_user_service_and_timer
    }

    [ "_$BATTERY_ALERT_ENV" = "_testing" ] || battery_alert_do_install

}

# this ensures the entire script is downloaded #
