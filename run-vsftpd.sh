#!/bin/bash

# Do not log to STDOUT by default:
if [ "$LOG_STDOUT" = "**Boolean**" ]; then
    export LOG_STDOUT=''
else
    export LOG_STDOUT='Yes.'
fi

# Create home dir and update vsftpd user db:
chown -R ftp:ftp /home/vsftpd/

if [ -e "1" ]; then
    echo "File Found"
else
	touch "/etc/vsftpd/1"
fi

if [ -e "/etc/vsftpd/virtual_users.txt" ]; then
    /usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db
fi

# Set passive mode parameters:
if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
    export PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
fi

CONF_FILE="/etc/vsftpd/vsftpd.conf"

declare -A FTP_CONFIG
FTP_CONFIG=(
    ["pasv_address"]="${PASV_ADDRESS}"
    ["pasv_max_port"]="${PASV_MAX_PORT}"
    ["pasv_min_port"]="${PASV_MIN_PORT}"
    ["pasv_addr_resolve"]="${PASV_ADDR_RESOLVE}"
    ["pasv_enable"]="${PASV_ENABLE}"
    ["file_open_mode"]="${FILE_OPEN_MODE}"
    ["local_umask"]="${LOCAL_UMASK}"
    ["xferlog_std_format"]="${XFERLOG_STD_FORMAT}"
    ["pasv_promiscuous"]="${PASV_PROMISCUOUS}"
    ["port_promiscuous"]="${PORT_PROMISCUOUS}"
)

for key in "${!FTP_CONFIG[@]}"; do
    value="${FTP_CONFIG[$key]}"
    if grep -q "^${key}=" "$CONF_FILE"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONF_FILE"
    else
        echo "${key}=${value}" >> "$CONF_FILE"
    fi
done

# Get log file path
export LOG_FILE=`grep xferlog_file /etc/vsftpd/vsftpd.conf|cut -d= -f2`

# stdout server info:
if [ ! $LOG_STDOUT ]; then
cat << EOB
	*************************************************
	*                                               *
	*    Docker image: trackhe/docker-vsftpd        *
	*    https://github.com/Trackhe/docker-vsftpd    *
	*                                               *
	*************************************************

	SERVER SETTINGS
	---------------
	· Log file: $LOG_FILE
	· Redirect vsftpd log to STDOUT: No.
EOB
else
    /usr/bin/ln -sf /dev/stdout $LOG_FILE
fi

# Run vsftpd:
&>/dev/null /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
