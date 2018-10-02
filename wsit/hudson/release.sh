#!/bin/sh
#
# Copyright (c) 2010, 2018 Oracle and/or its affiliates. All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Distribution License v. 1.0, which is available at
# http://www.eclipse.org/org/documents/edl-v10.php.
#
# SPDX-License-Identifier: BSD-3-Clause
#

while getopts :r:j:k:l:v:s:b:m:w:dh arg
do
    case "$arg" in
        r)  RELEASE_VERSION="${OPTARG:?}" ;;
        v)  RELEASE_REVISION="${OPTARG:?}" ;;
        j)  JAXWS_VERSION="${OPTARG:?}" ;;
        k)  JAXB_VERSION="${OPTARG:?}" ;;
        l)  MAVEN_USER_HOME="${OPTARG:?}" ;;
        s)  MAVEN_SETTINGS="${OPTARG:?}" ;;
        b)  METRO_PROMOTION_BUILD="${OPTARG:?}" ;;
        m)  SOURCES_VERSION="${OPTARG:?}" ;;
        w)  WORKROOT="${OPTARG:?}" ;;
        u)  WWW_SVN_USER="${OPTARG:?}" ;;
        p)  WWW_SVN_PASSWORD="${OPTARG:?}" ;;
        d)  debug=true ;;
        h)
            echo "Usage: release.sh [-r RELEASE_VERSION] --mandatory, the release version string, for example 2.3.1"
            echo "                   [-v RELEASE_REVISION] or [-b METRO_PROMOTION_BUILD] --either one is needed, the svn revision number or the hudson promotion job(metro-trunk-promotion) build number"
            echo "                   [-j JAXWS_VERSION] --mandatory, the dependent JAXWS release version string, for example 2.2.10"
            echo "                   [-k JAXB_VERSION] --optional, the dependent JAXB release version string, for example 2.2.11, it uses imported jaxb version from jaxws for default if not specified"
            echo "                   [-l MVEN_USER_HOME] -- optional, alternative maven local repository location"
            echo "                   [-w WORKROOT] -- optional, default is current dir (`pwd`)"
            echo "                   [-m SOURCES_VERSION] -- optional, version in pom.xml need to be repaced with \$RELEASE_VERSION, default is \${RELEASE_VERSION}-SNAPSHOT"
            echo "                   [-s MAVEN_SETTINGS] --optional, alternative maven settings.xml"
            echo "                   [-u WWW_SVN_USER] --optional, the svn scm username for commit the www docs, if not specified it uses cached credential"
            echo "                   [-p WWW_SVN_PASSWORD] --optional the svn scm password for commit the www docs"
            echo "                   [-d] -- debug mode"
            exit ;;
        "?")
            echo "ERROR: unknown option \"$OPTARG\"" 1>&2
            echo "" 1>&2 ;;
    esac
done

if [ "$M2_HOME" = "" -o ! -d $M2_HOME ]; then
    echo "ERROR: Check your M2_HOME: $M2_HOME"
    exit 1
fi

if [ "$JAVA_HOME" = "" -o ! -d $JAVA_HOME ]; then
    echo "ERROR: Check your JAVA_HOME: $JAVA_HOME"
    exit 1
fi
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH

PROXYURL=www-proxy.us.oracle.com
PROXYPORT=80

export http_proxy=$PROXYURL:$PROXYPORT
export https_proxy=$http_proxy


export MAVEN_OPTS="-Xms256m -Xmx768m -XX:PermSize=256m -XX:MaxPermSize=512m -Dhttp.proxyHost=$PROXYURL -Dhttp.proxyPort=$PROXYPORT -Dhttps.proxyHost=$PROXYURL -Dhttps.proxyPort=$PROXYPORT"

if [ -n "$WWW_SVN_USER"  -a -n "$WWW_SVN_PASSWORD" ]; then
    AUTH="--username $WWW_SVN_USER --password $WWW_SVN_PASSWORD --no-auth-cache"
else
    AUTH=""
fi

if [ "$MAVEN_USER_HOME" = "" ]; then
     user=${LOGNAME:-${USER-"`whoami`"}}
     MAVEN_USER_HOME="/scratch/$user/.m2/repository"
fi

if [ -n "$MAVEN_SETTINGS" ]; then
    MAVEN_SETTINGS="-s $MAVEN_SETTINGS"
fi

if [ "$WORKROOT" = "" ]; then
    WORKROOT=`pwd`
fi

if [ "$MAVEN_USER_HOME" = "" ]; then
    MAVEN_LOCAL_REPO="-Dmaven.repo.local=${WORKROOT}/.m2/repository"
else
    MAVEN_LOCAL_REPO="-Dmaven.repo.local=${MAVEN_USER_HOME}"
fi

if [ "$JAXWS_VERSION" = "" ]; then
    echo "ERROR: JAXWS version is null"
    exit 1
fi

if [ "$RELEASE_REVISION" = "" ]; then
    if [ "$METRO_PROMOTION_BUILD" = "" ]; then
        echo "ERROR: you need to either give the -r with the release revision, or give the -b with the promotion hudson build number"
        exit 1
    else
        RELEASE_REVISION=`wget -q -O - "http://prg10044.cz.oracle.com/hudson/job/metro-trunk-promotion/$METRO_PROMOTION_BUILD/artifact/revision.txt"`
    fi
fi

echo "Release Revision: $RELEASE_REVISION"
if [ "$RELEASE_REVISION" = "" -o "$RELEASE_REVISION" = "0" ]; then
   exit 1;
fi

cd $WORKROOT
if [ -e wsit ] ; then
   echo "INFO: Removing old Metro workspace"
   rm -rf wsit
fi

echo "INFO: Checking out Metro sources for release using revision: $RELEASE_REVISION"
svn checkout --non-interactive -q -r $RELEASE_REVISION https://svn.java.net/svn/wsit~svn/trunk/wsit

cd wsit
chmod +x ./hudson/*.sh

SOURCES_VERSION=${SOURCES_VERSION:-"${RELEASE_VERSION}-SNAPSHOT"}
echo "INFO: Replacing project version $SOURCES_VERSION in sources with new release version $RELEASE_VERSION"
echo "INFO: ./hudson/changeVersion.sh $SOURCES_VERSION $RELEASE_VERSION pom.xml"
./hudson/changeVersion.sh $SOURCES_VERSION $RELEASE_VERSION pom.xml
if [ -n "$JAXWS_VERSION" ]; then
    echo "INFO: dependent JAXWS RI version is $JAXWS_VERSION "
    perl -i -pe "s|<jaxws.ri.version>.*</jaxws.ri.version>|<jaxws.ri.version>$JAXWS_VERSION</jaxws.ri.version>|g" boms/bom/pom.xml
fi
  
DEPENDENCIES_PROPERTIES="-Djaxws.version=$JAXWS_VERSION"
if [ -n "$JAXB_VERSION" ]; then
    DEPENDENCIES_PROPERTIES="$DEPENDENCIES_PROPERTIES -Djaxb.version=$JAXB_VERSION"
fi

if [ "$debug" = "true" ]; then
    echo "DEBUG: build while no deploy"
    echo "INFO: mvn $MAVEN_SETTINGS -B -C -DskipTests=true $MAVEN_LOCAL_REPO $DEPENDENCIES_PROPERTIES -Prelease-profile,release-sign-artifacts,release-docs clean install" 
    mvn $MAVEN_SETTINGS -B -C -DskipTests=true $MAVEN_LOCAL_REPO $DEPENDENCIES_PROPERTIES -Prelease-profile,release-sign-artifacts,release-docs clean install 
else
    echo "INFO: Build and Deploy ..."
    mvn $MAVEN_SETTINGS -B -C -DskipTests=true $MAVEN_LOCAL_REPO $DEPENDENCIES_PROPERTIES -Prelease-profile,release-sign-artifacts,release-docs clean install deploy 
fi
if [ $? -ne 0 ]; then
      exit 1
fi
cd $WORKROOT
if [ "$debug" = "true" ]; then
    echo "DEBUG: debug only, not actually tagging ..."
    echo "DEBUG: svn $AUTH --non-interactive copy wsit https://svn.java.net/svn/wsit~svn/tags/$RELEASE_VERSION -m \"Tag release $RELEASE_VERSION \""
else
    echo "INFO: Tagging release $RELEASE_VERSION ..."
    svn $AUTH --non-interactive copy wsit https://svn.java.net/svn/wsit~svn/tags/$RELEASE_VERSION -m "Tag release $RELEASE_VERSION"
fi

echo "INFO: Updating www docs ..."
if [ -d "www" ]; then
    rm -rf www
fi
echo "INFO: svn checkout --non-interactive --depth=empty https://svn.java.net/svn/metro~svn/trunk/www"
svn checkout --non-interactive --depth=empty https://svn.java.net/svn/metro~svn/trunk/www
cd www || exit 1
mkdir -p $RELEASE_VERSION
echo "INFO: cp -r $WORKROOT/wsit/docs/guide/target/www/* $RELEASE_VERSION/"
cp -r $WORKROOT/wsit/docs/guide/target/www/* $RELEASE_VERSION/
svn add --non-interactive $RELEASE_VERSION

echo "INFO: Update latest download page link to $RELEASE_VERSION"
svn --non-interactive update -q latest
sed -i "s#URL=https://metro.java.net/.*/#URL=https://metro.java.net/$RELEASE_VERSION/#" latest/download.html

echo "INFO: add $RELEASE_VERSION to the left side bar"
svn --non-interactive update -q __modules
line=`sed -n '/    <a href=\"#\">Download<\/a>/=' __modules/left_sidebar.htmlx`
line=`expr $line + 1`
appendLine="\ \ \ \ \ \ \ \ <li><a href=\"http://metro.java.net/$RELEASE_VERSION/\" match=\"/$RELEASE_VERSION/.*\">$RELEASE_VERSION</a>"
sed -i "$line a\
$appendLine" __modules/left_sidebar.htmlx

if [ "$debug" = "true" ]; then
    echo "DEBUG: debug only, not commit the docs."
    echo "DEBUG: svn $AUTH --non-interactive commit -m \"Metro $RELEASE_VERSION\" ."
else
    echo "INFO: commit the updated docs"
    svn $AUTH --non-interactive commit -m "Metro $RELEASE_VERSION" .
fi
