FROM ubuntu:14.04
MAINTAINER Thibaut Lapierre <root@epheo.eu>
#Forked from https://github.com/neildunbar/mariadb55

# Configure apt
RUN	apt-get -y update && apt-get install -y software-properties-common

RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
RUN add-apt-repository 'deb http://ftp.igh.cnrs.fr/pub/mariadb/repo/10.0/ubuntu trusty main'

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
RUN add-apt-repository 'deb http://repo.percona.com/apt trusty main'

# Make apt and MariaDB happy with the docker environment
#RUN	echo "#!/bin/sh\nexit 101" >/usr/sbin/policy-rc.d
#RUN	chmod +x /usr/sbin/policy-rc.d
#RUN	cat /proc/mounts >/etc/mtab # ??

# Install MariaDB
RUN	LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get -y update
RUN	LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y iproute mariadb-galera-server galera rsync netcat-openbsd socat pv percona-xtrabackup

# this is for testing - can be commented out later
# RUN	LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y iputils-ping net-tools

# Add in extra wsrep scripts
ADD bin/wsrep_sst_common 			/usr/bin/wsrep_sst_common
ADD bin/wsrep_sst_xtrabackup-v2 	/usr/bin/wsrep_sst_xtrabackup-v2

# Clean up
RUN	rm -r /var/lib/mysql

# Add config(s) - standalong and cluster mode
ADD etc/my-cluster.cnf 			/etc/mysql/my-cluster.cnf
ADD etc/my-init.cnf 			/etc/mysql/my-init.cnf


ADD bin/mariadb-setrootpassword /usr/bin/mariadb-setrootpassword
ADD bin/mariadb-start /usr/bin/mariadb-start

EXPOSE 3306 4567 4444

CMD ["/usr/bin/mariadb-start"]
