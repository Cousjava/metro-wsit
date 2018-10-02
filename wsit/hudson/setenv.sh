#!/bin/bash -ex
#
# Copyright (c) 2012, 2018 Oracle and/or its affiliates. All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Distribution License v. 1.0, which is available at
# http://www.eclipse.org/org/documents/edl-v10.php.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# $1 - zip
# $2 - destdir
_unzip() {
    rm -rf $2 || true
    mkdir -p $2 && unzip -q $1 -d $2
}

set_common() {
    if [ -z "$WORK_DIR" ]; then
        WORK_DIR=/tmp
        echo "setting WORK_DIR to $WORK_DIR"
    fi

    GF_WORK_DIR=$WORK_DIR/tmp-gf
    METRO_WORK_DIR=$WORK_DIR/tmp-metro

    if [ -z "$MVN_SETTINGS" ]; then
        MVN_SETTINGS="$HOME/.m2/settings.xml"
    fi
}

set_ports() {
    if [ -z "$ADMIN_PORT" ] ; then
        ADMIN_PORT=4848
    fi
    if [ -z "$INSTANCE_PORT" ] ; then
        INSTANCE_PORT=8080
    fi
    if [ -z "$SSL_PORT" ] ; then
        SSL_PORT=8181
    fi
    if [ -z "$ALTERNATE_PORT" ] ; then
        ALTERNATE_PORT=7777
    fi
    if [ -z "$ORB_PORT" ] ; then
        ORB_PORT=3700
    fi
    if [ -z "$JMS_PORT" ] ; then
        JMS_PORT=7676
    fi
    if [ -z "$JMX_PORT" ] ; then
        JMX_PORT=8686
    fi
    if [ -z "$ORB_SSL_PORT" ] ; then
        ORB_SSL_PORT=3820
    fi
    if [ -z "$ORB_SSL_MUTUALAUTH_PORT" ] ; then
        ORB_SSL_MUTUALAUTH_PORT=3920
    fi
}

print_env() {
    echo "Environment settings:"
    echo  "====================="
    echo "JAVA_HOME: $JAVA_HOME"
    echo "ANT_HOME: $ANT_HOME"
    echo "M2_HOME: $M2_HOME"
    echo "JAVA_OPTS: $JAVA_OPTS"
    echo "ANT_OPTS: $ANT_OPTS"
    echo "MAVEN_OPTS: $MAVEN_OPTS"
    echo "MVN_SETTINGS: $MVN_SETTINGS"
    echo "PATH: $PATH"
    echo
}

print_test_env() {
    echo "GlassFish SVN root: $GF_SVN_ROOT"
    echo "GlassFish zip: $GF_ZIP"
    echo "Metro zip: $METRO_ZIP"
    echo "Working directory: $WORK_DIR"
    echo "Working directory - GlassFish: $GF_WORK_DIR"
    echo "Working directory - Metro: $METRO_WORK_DIR"
}

print_ports() {
    echo "Ports:"
    echo "ADMIN_PORT: $ADMIN_PORT"
    echo "INSTANCE_PORT: $INSTANCE_PORT"
    echo "SSL_PORT: $SSL_PORT"
    echo "ALTERNATE_PORT: $ALTERNATE_PORT"
    echo "ORB_PORT: $ORB_PORT"
    echo "JMS_PORT: $JMS_PORT"
    echo "JMX_PORT: $JMX_PORT"
    echo "ORB_SSL_PORT: $ORB_SSL_PORT"
    echo "ORB_SSL_MUTUALAUTH_PORT: $ORB_SSL_MUTUALAUTH_PORT"
}

install_metro() {
    echo "Installing Metro..."
    _unzip $METRO_ZIP $METRO_WORK_DIR
    pushd $METRO_WORK_DIR/metro
    ant -Das.home=$1 -f metro-on-glassfish.xml install
    popd
}

create_domain() {
    rm -rf $AS_HOME/domains/domain1
    echo "AS_ADMIN_PASSWORD=" > $GF_WORK_DIR/temppwd
    $AS_HOME/bin/asadmin --user admin --passwordfile $GF_WORK_DIR/temppwd create-domain --adminport ${ADMIN_PORT} --domainproperties jms.port=${JMS_PORT}:domain.jmxPort=${JMX_PORT}:orb.listener.port=${ORB_PORT}:http.ssl.port=${SSL_PORT}:orb.ssl.port=${ORB_SSL_PORT}:orb.mutualauth.port=${ORB_SSL_MUTUALAUTH_PORT} --instanceport ${INSTANCE_PORT} domain1
}
