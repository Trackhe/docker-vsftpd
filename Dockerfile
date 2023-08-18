FROM ubuntu:latest

LABEL Description="vsftpd Docker image based on Ubuntu." \
	License="Apache License 2.0" \
	Usage="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd trackhe/docker-vsftpd:latest" \
	Version="1.0"

RUN apt update && apt upgrade -y
RUN apt install -y bash openssl vsftpd curl libpam-pwdfile

ENV PASV_ADDRESS **IPv4**
ENV PASV_ADDR_RESOLVE NO
ENV PASV_MIN_PORT 8600
ENV PASV_MAX_PORT 8700
ENV LOG_STDOUT NO
ENV LOCAL_UMASK 077

COPY vsftpd.conf /tmp/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/sbin/

RUN \
  mkdir -p /home/www-data && \
  addgroup --gid 33 www-data \
  adduser --uid 33 --gid 33 -S -D -G www-data -h /home/www-data -s /sbin/nologin www-data && \
  chown -R www-data:www-data /home/www-data && \
  mkdir -p /var/run/vsftpd/empty && \
  mkdir -p /home/vsftpd && \
  mkdir -p /etc/vsftpd/users_config && \
  chown -R www-data:www-data /home/vsftpd

RUN chmod +x /usr/sbin/run-vsftpd.sh

VOLUME /home/vsftpd
VOLUME /etc/vsftpd
VOLUME /var/log/vsftpd

EXPOSE 20 21 8600-8700

CMD ["/usr/sbin/run-vsftpd.sh"]
