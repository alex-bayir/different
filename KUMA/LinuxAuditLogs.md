# Configuring sending Audit events from Linux systems

## Automated configuration of logging and sending the audit log

To automate the logging and sending of Linux system events, you need
to use [audit.sh](./audit.sh) script and run a file with the following contents:

- to send only to SIEM: ```sudo bash audit.sh -h siem.example.com -p 5140```
- for logging to a file only: ```sudo bash audit.sh -s```
- for logging to a file and SIEM: ```sudo bash audit.sh -h siem.example.com -p 5140 -s```

## Manual configuration of the audit log

To log Linux system events, you need to create a file with the following [content](https://raw.githubusercontent.com/Neo23x0/auditd/refs/heads/master/audit.rules).
This file must have a root owner and have read and write permissions for root only. To
apply the rules, run the following command, specifying the necessary
superuser rights or their delegated part to execute the "auditctl" command.

```sh
sudo chmod 600 auditd.rules
sudo auditctl -R auditd.rules
```

To send Linux system events via syslog, you need to make the following settings:

1. To change the contents of the file:

    - For auditd version <3.x: /etc/audisp/plugins.d/syslog.conf

        ```sh
        active = yes
        direction = out
        path = builtin_syslog
        type = builtin
        args = LOG_INFO LOG_LOCAL6
        ```

    - For auditd version >=3.x: /etc/audit/plugins.d/syslog.conf

        ```sh
        active = yes
        direction = out
        path = /sbin/audisp-syslog
        type = always
        args = LOG_INFO LOG_LOCAL6
        format = string
        ```

2. Set the value of the ```name_format = HOSTNAME``` parameter

    - For auditd version <3.x: /etc/audisp/plugins.d/syslog.conf
    - For auditd version >=3.x: /etc/audit/plugins.d/syslog.conf

3. Create a file (for example, siem.conf) of logging rules in /etc/rsyslog.d:

    ```sh
    local6.=info @@siem.example.com:xxxx  # to external system
    local6.=info /var/log/audit/audit.log # to local file
    ```

4. Restart rsyslog:

    ```sh
    systemctl restart rsyslog
    ```
