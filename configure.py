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

dockerclient.build(path='.', tag='openstack/mariadb') #Don't work

db_container_id = dockerclient.create_container('openstack/mariadb', 
	environment={'CLUSTER': 'INIT', 'NODE_ADDR': 'node01'}, 
	volumes=['/var/lib/mysql', '/etc/ssl/mysql'],
	ports=[4567, 3306, 4444])

dockerclient.start(db_container_id, 
	binds={
	    '/data/mysql': '/var/lib/mysql', 
	    '/data/mysql-ssl': '/etc/ssl/mysql'
	},
	port_bindings={4567: 4567, 3306: 3306, 4444: 4444})
