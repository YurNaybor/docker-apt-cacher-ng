# some documentation and guidance: https://fabianlee.org/2018/02/11/ubuntu-a-centralized-apt-package-cache-using-apt-cacher-ng
# also https://www.pitt-pladdy.com/blog/_20150720-132951_0100_Home_Lab_Project_apt-cacher-ng_with_CentOS/
FROM debian:stretch-slim

ARG APT_HTTP_PROXY="DIRECT"
ARG APT_HTTPS_PROXY="DIRECT"

RUN echo "Acquire::http { Proxy \"${APT_HTTP_PROXY}\"; };" >> /etc/apt/apt.conf.d/02proxy
RUN echo "Acquire::https { Proxy \"${APT_HTTPS_PROXY}\"; };" >> /etc/apt/apt.conf.d/02proxy

VOLUME /var/cache/apt-cacher-ng

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
      apt-cacher-ng \
      netcat \
      curl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /
# accept additional files if beeing used as a mirror (e.g. by simple-cdd-build, centos)
RUN echo "VfilePatternEx: (^|.*)(extrafiles|\.cfg|\?release=[0-9]+&arch=.*|.*/RPM-GPG-KEY-.*)$" >> /etc/apt-cacher-ng/acng.conf
RUN echo "PfilePatternEx: (^|.*)(README|\.iso|\.exe|/doc/.*|.*\.txt|00-INDEX|debian-manifesto)$" >> /etc/apt-cacher-ng/acng.conf
RUN echo "WfilePatternEx: (^|.*)(extrafiles|\.cfg|\?release=[0-9]+&arch=.*|.*/RPM-GPG-KEY-.*)$" >> /etc/apt-cacher-ng/acng.conf
# merging centos mirrors
RUN echo "Remap-centos: file:centos_mirrors /centos" >> /etc/apt-cacher-ng/acng.conf
RUN curl -sSL http://www.centos.org/download/full-mirrorlist.csv | sed 's/^.*"http:/http:/' | sed 's/".*$//' | grep ^http > /etc/apt-cacher-ng/centos_mirrors
#for now allow all ssl connection
RUN echo "PassThroughPattern: .*" >> /etc/apt-cacher-ng/acng.conf
#add custom backends
COPY backends/backends_docker-ce /etc/apt-cacher-ng/
RUN echo "Remap-docker: http://fakerepo.benjaminvoigt.info ; file:backends_docker-ce" >> /etc/apt-cacher-ng/acng.conf

EXPOSE 3142
HEALTHCHECK CMD nc -vz localhost 3142

#ENTRYPOINT /docker-entrypoint.sh
CMD chmod 777 /var/cache/apt-cacher-ng && service apt-cacher-ng start && tail -f /var/log/apt-cacher-ng/*
