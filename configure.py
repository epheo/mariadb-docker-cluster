#!/usr/bin/python

import os
import errno
import docker

def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

make_sure_path_exists('/data/mysql')
make_sure_path_exists('/data/mysql-ssl')

dockerclient = docker.Client(base_url='unix://var/run/docker.sock',
                  version='1.9',
                  timeout=10)

f = open("Dockerfile", "r+")
f.read()

db_container = dockerclient.build(path='.', tag='openstack/mariadb')

dockerclient.start(container, publish_all_ports=True)
