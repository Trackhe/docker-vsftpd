FROM alpine:latest

ARG USER_ID=14
ARG GROUP_ID=50

MAINTAINER Fer Uria <fauria@gmail.com>
LABEL Description="vsftpd Docker image based on Alpine." \
	License="Apache License 2.0" \
	Usage="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd trackhe/docker-vsftpd:latest" \
	Version="1.0"

RUN apk update
RUN apk upgrade
RUN apk --update --no-cache add \
		bash \
		openssl \
		vsftpd \
		openrc \
		linux-pam-dev

RUN apk --update --no-cache --virtual add .build-dependencies build-base linux-pam-dev curl tar

RUN apk add db-utils

ENV PASV_ADDRESS **IPv4**
ENV PASV_ADDR_RESOLVE NO
ENV PASV_MIN_PORT 8600
ENV PASV_MAX_PORT 8700
ENV LOG_STDOUT NO

COPY vsftpd.conf /etc/vsftpd/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/sbin/

RUN \
  mkdir /pam && \
  cd pam && \
  curl -sSL https://github.com/prapdm/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1 && \
  make install && \
  cd .. && \
  rm -rvf pam && \
  mkdir -p /home/www-data && \ 
  addgroup -g 82 -S www-data && \
  adduser -u 82 -S -D -G www-data -h /home/www-data -s /sbin/nologin www-data && \
  chown -R www-data:www-data /home/www-data && \
  mkdir -p /var/run/vsftpd/empty && \
  mkdir -p /home/vsftpd && \
  mkdir -p /conf/vsftpd && \
  mkdir -p /conf/vsftpd/users_config && \
  chown -R ftp:ftp /home/vsftpd && \
  echo "Delete Build pkgs" && \
  apk del .build-dependencies && \
  rm -rvf /var/cache/apk/* && \
  rm -rvf /tmp/* && \
  rm -rvf /src  && \
  rm -rvf /var/log/* 

RUN chmod +x /usr/sbin/run-vsftpd.sh

VOLUME /home/vsftpd
VOLUME /etc/vsftpd
VOLUME /var/log/vsftpd

EXPOSE 20 21 8600-8700

CMD ["/usr/sbin/run-vsftpd.sh"]
