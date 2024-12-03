# syntax = docker/dockerfile:1.1-experimental

#
#	MetaCall Guix by Parra Studios
#	Docker image for using Guix in a CI/CD environment.
#
#	Copyright (C) 2016 - 2024 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.
#

FROM alpine:3.20 AS guix

ARG GUIX_FILENAME=guix-binary-1.4.0.x86_64-linux.tar.xz
ARG GUIX_CHECKSUM=236ca7c9c5958b1f396c2924fcc5bc9d6fdebcb1b4cf3c7c6d46d4bf660ed9c9
ARG GUIX_BUILDER_COUNT=16

# Copy entry point
COPY entry-point.sh /entry-point.sh

# Install Guix
RUN mkdir -p /gnu/store \
	&& addgroup guixbuild \
	&& addgroup guix-builder \
	&& chgrp guix-builder -R /gnu/store \
	&& chmod 1777 /gnu/store \
	&& for i in `seq -w 1 ${GUIX_BUILDER_COUNT}`; do \
			adduser -G guixbuild -h /var/empty -s `which nologin` -S guixbuilder$i; \
		done \
	&& wget -O /tmp/${GUIX_FILENAME} https://ftp.gnu.org/gnu/guix/${GUIX_FILENAME} \
	&& echo "${GUIX_CHECKSUM} /tmp/${GUIX_FILENAME}" | sha256sum -c \
	&& tar xJvf /tmp/${GUIX_FILENAME} -C / \
	&& mkdir -p /root/.config/guix \
	&& ln -sf /var/guix/profiles/per-user/root/current-guix /root/.config/guix/current \
	&& mkdir -p /usr/local/bin \
	&& ln -s /var/guix/profiles/per-user/root/current-guix/bin/guix /usr/local/bin/ \
	&& mkdir -p /usr/local/share/info \
	&& for i in /var/guix/profiles/per-user/root/current-guix/share/info/*; do \
			ln -s $i /usr/local/share/info/; \
		done \
	&& chmod +x /entry-point.sh \
	&& source $GUIX_PROFILE/etc/profile \
	&& guix archive --authorize < /root/.config/guix/current/share/guix/ci.guix.gnu.org.pub

ENV GUIX_PROFILE="/root/.config/guix/current" \
	GUIX_LOCPATH="/root/.guix-profile/lib/locale/" \
	LANG="en_US.UTF-8"

ENTRYPOINT ["/entry-point.sh"]
CMD ["sh"]
