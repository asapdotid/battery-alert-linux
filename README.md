<p align="center">
    <img src="assets/battery-alert-linux.png" width="600" />
</p>

# Battery Alert for Linux

Full & Low battery alert program for `Linux` users written in bash.
Desktop notification when battery full or falls below a threshold percentage of your choice.

Just a friendly reminder to charge your battery, which might get low if you don't give it a boost. We've all been there, where your laptop dies and you have to find a charger, reboot, and restart all your programs. It's a hassle, i know!

## Reference:

`ArchWiki - Desktop Notification` [doc]([Desktop Notification](https://wiki.archlinux.org/title/Desktop_notifications))

## Requirement Package

-   Desktop notifications [wiki](https://wiki.archlinux.org/title/Desktop_notifications)
-   Notify-send (Libnotify) [wiki](https://man.archlinux.org/man/notify-send.1.en)
-   Paplay - PulseAudio [wiki](https://linux.die.net/man/1/paplay)
-   Pw-play - Pipewire [docs](https://docs.pipewire.org/page_man_pw-cat_1.html)
-   eSpeak [wiki](https://espeak.sourceforge.net/)

## Installing and Updating

### Install & Update Script

To **install** or **update** battrey alert, you should run the [install script][2]. To do that, you may either download and run the script manually, or use the following `cURL` or `Wget` command:

```sh
curl -o- https://raw.githubusercontent.com/asapdotid/battery-alert-linux/refs/heads/main/install.sh | bash
```

```sh
wget -qO- https://raw.githubusercontent.com/asapdotid/battery-alert-linux/refs/heads/main/install.sh | bash
```

#### Additional Notes

-   If the environment variable `$XDG_DATA_HOME` or `$XDG_CONFIG_HOME` is present, it will place the `battrey alert` files there.</sub>

-   The installer can use `git`, `curl`, or `wget` to download `battrey alert`, whichever is available.
-

### Custom Variables for Alert

Optional of customize default variables:

| Variable              | Default | Description                                 |
| --------------------- | ------- | ------------------------------------------- |
| ALERT_SOUND           | `true`  | Alert with `sound` or `espeak` (true/false) |
| ALERT_FULL            | `true`  | Alert for full battery (true/false)         |
| ALERT_EMPTY           | `true`  | Alert for empty battery (true/false)        |
| ALERT_EMPTY_TRHESHOLD | `30`    | Empty trheshold for empty battery (%)       |

Default config `/home/$USER/.local/share/battery-alert/default.conf`

```bash
# default variables, optional for customize
ALERT_SOUND=true
ALERT_FULL=true
ALERT_EMPTY=true
ALERT_EMPTY_TRHESHOLD=30
```

## Check Battery Alert service & timer

> A timer will run the service every 2 minutes

```bash
systemctl --user list-timers
```

## To Do

[ ] Custom set timer

If any issue please contact me [@asapdotid](mailto:asapdotid@gmail.com) 😃

<img class="float-left rounded-2 avatar-user" src="https://avatars.githubusercontent.com/u/34257858?s=96&amp;v=4" width="48" height="48" alt="@asapdotid">
