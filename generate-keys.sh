#!/bin/bash

set -eu

DIR=`pwd`/openssl
PRIV=$DIR/private
PASSPHRASE=`openssl rand -base64 32`

DESTDIR=/data/mysql-ssl
OPENSSLCNF=openssl.cnf

if [ "$#" -ge 1 ]; then
    DESTDIR="$1"
fi

if [[ -e $DESTDIR/ca.pem &&
      -e $DESTDIR/server-cert.pem &&
      -e $DESTDIR/server-key.pem &&
      -e $DESTDIR/root/adminuser.pem ]]; then
    echo "All necessary certificates already exist in $DESTDIR"
    echo "To generate new certificates, you must first remove the old ones."
    exit 0
fi

echo "Generating new certs to be placed in $DESTDIR"

if [ ! -e "$OPENSSLCNF" ]; then
    if [ -e /etc/mysql/openssl.cnf ]; then
        OPENSSLCNF=/etc/mysql/openssl.cnf
    else
        echo "OpenSSL configuration file is missing!"
        exit 1
    fi
fi

if [ ! -d "$DESTDIR" ]; then
    mkdir $DESTDIR
fi

if [ ! -d "$DESTDIR/root" ]; then
    mkdir $DESTDIR/root
fi

rm -rf $DIR

if [ ! -d "$DIR" ]; then
    mkdir $DIR
fi

if [ ! -d "$DIR/newcerts" ]; then
    mkdir $DIR/newcerts
fi

if [ ! -d "$PRIV" ]; then
    mkdir $PRIV
fi

# Create necessary files
if [ ! -e "$DIR/index.txt" ]; then
    touch "$DIR/index.txt"
fi

if [ ! -e "$DIR/serial" ]; then
    echo "01" > $DIR/serial
fi

#
# Generation of Certificate Authority(CA)
#
echo "Now creating the certificate authority."
openssl req -new \
            -x509 \
            -keyout $PRIV/cakey.pem \
            -out $DIR/ca-cert.pem \
            -days 3650 \
            -config $OPENSSLCNF \
            -subj "/C=XX/ST=XX/L=XX/O=Galera Cluster/OU=Galera Cluster/CN=MySQL admin" \
            -passout pass:$PASSPHRASE

#
# Create server request and key
#
echo "Now creating the server key."
openssl req -new \
            -keyout $DIR/server-key.pem \
            -out $DIR/server-req.pem \
            -days 3650 \
            -config $OPENSSLCNF \
            -subj "/C=XX/ST=XX/L=XX/O=Galera Cluster/OU=Galera Cluster/CN=MySQL server" \
            -passout pass:$PASSPHRASE

#
# Remove the passphrase from the key
#
echo "Removing passphrase from the server key."
openssl rsa -in $DIR/server-key.pem \
            -out $DIR/server-key.pem \
            -passin pass:$PASSPHRASE

#
# Sign server cert
#
echo "Signing the server cert."
openssl ca -batch \
           -cert $DIR/ca-cert.pem \
           -out $DIR/server-cert.pem \
           -config $OPENSSLCNF \
           -passin pass:$PASSPHRASE \
           -infiles $DIR/server-req.pem

#
# Create client request and key
#
echo "Now creating the client key."
openssl req -new \
            -keyout $DIR/client-key.pem \
            -out $DIR/client-req.pem \
            -days 3650 \
            -config $OPENSSLCNF \
            -subj "/C=XX/ST=XX/L=XX/O=Galera Cluster/OU=Galera Cluster/CN=MySQL user" \
            -passout pass:$PASSPHRASE

#
# Remove the passphrase from the key
#
echo "Now removing the passphrase from the client key."
openssl rsa -in $DIR/client-key.pem \
            -out $DIR/client-key.pem \
            -passin pass:$PASSPHRASE

#
# Sign client cert
#
echo "Now signing the client key."
openssl ca -batch \
           -cert $DIR/ca-cert.pem \
           -out $DIR/client-cert.pem \
           -config $OPENSSLCNF \
           -passin pass:$PASSPHRASE \
           -infiles $DIR/client-req.pem

cp $DIR/ca-cert.pem $DESTDIR/ca.pem
cp $DIR/server-cert.pem $DESTDIR/server-cert.pem
cp $DIR/server-key.pem $DESTDIR/server-key.pem
cp $DIR/client-cert.pem $DESTDIR/root/adminuser.pem

cp $DIR/client-cert.pem $DESTDIR/client-cert.pem
cp $DIR/client-key.pem $DESTDIR/client-key.pem

echo "Keep $DESTDIR/client-key.pem and $DESTDIR/client-cert.pem safe, as \
these are what you need to connect to the database as \"adminuser\""
