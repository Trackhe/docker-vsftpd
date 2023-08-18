#!/bin/bash

if [ -e "/etc/vsftpd/1" ]; then
    echo "File Found"
else
	touch "/etc/vsftpd/1"
#    cp /tmp/vsftpd.conf /etc/vsftpd/
#    if [[ ! -e /etc/vsftpd/vsftpd.pem ]]; then
#	echo "Creating the certificate"
	openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
		-keyout /etc/vsftpd/vsftpd-key.pem -out /etc/vsftpd/vsftpd.pem \
		-batch || { echo "Failed to create the vsftpd certificate"; exit 1; }
#    fi
fi

if [ -e "/etc/vsftpd/virtual_users" ]; then
    echo "User File Exist"
else
    touch /etc/vsftpd/virtual_users
fi

chmod 600 /etc/vsftpd/virtual_users

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
    ["local_umask"]="${LOCAL_UMASK}"
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

# Run vsftpd:
&>/dev/null /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf