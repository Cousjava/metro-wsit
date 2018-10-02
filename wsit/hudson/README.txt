#
# Copyright (c) 2010, 2018 Oracle and/or its affiliates. All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Distribution License v. 1.0, which is available at
# http://www.eclipse.org/org/documents/edl-v10.php.
#
# SPDX-License-Identifier: BSD-3-Clause
#

Place containing all hudson job scripts
most of them are usable also in local environment

GlassFish workspace root refers to:
    svn co https://svn.java.net/svn/glassfish~svn/trunk/main/

appserv-tests workspace root refers to:
    svn co https://svn.java.net/svn/glassfish~svn/trunk/v2/appserv-tests
  which must contain at least:
    svn co https://svn.java.net/svn/glassfish~svn/trunk/v2/appserv-tests/config
    svn co https://svn.java.net/svn/glassfish~svn/trunk/v2/appserv-tests/devtests/webservice
    svn co https://svn.java.net/svn/glassfish~svn/trunk/v2/appserv-tests/lib
    svn co https://svn.java.net/svn/glassfish~svn/trunk/v2/appserv-tests/util


changeVersion.sh <old_string> <new_string> <file>

    recursively find all <file>s and replace <old_string> with <new_string> there
    typical usage is:

        cd $WSIT_HOME
        changeVersion.sh "2.3-SNAPSHOT" "2.3-b05" pom.xml

   TODO: consider deprecating and replacing this script with:
   cd $WSIT_HOME && mvn versions:set -DnewVersion=<version> -f bom/pom.xml'


cts-smoke.sh -c <cts.zip> (-g <glassfish.zip> || -s <gfsvnroot>) [-w <workingdir>] [-m <metro.zip>]

    unzip GlassFish to workingdir, optionally install Metro on top of it,
    re-create default domain1 and run CTS Smoke test suite

    option      env_var         description
  -------------------------------------------
  mandatory:
    -c <file>   $CTS_ZIP        CTS-smoke tests zip distribution, usually: javaee-smoke-6.0_latest.zip
  one of:
    -s <dir>    $GF_SVN_ROOT    GlassFish workspace root
    -g <file>   $GF_ZIP         GlassFish zip distribution to test
                                defaults to: $GF_SVN_ROOT/appserver/distributions/glassfish/target/glassfish.zip
  optional:
    -m <file>   $METRO_ZIP      Metro zip distribution to test
    -w <dir>    $WORK_DIR       working directory
                                defaults to: /tmp
  Note:
    command line options take precedence over environment variables


devtests.sh -d <devtestssvnroot> (-g <glassfish.zip> || -s <gfsvnroot>) [-w <workingdir>] [-m <metro.zip>]

    unzip GlassFish to workingdir, optionally install Metro on top of it,
    re-create default domain1 and run webservices devtests

    option      env_var         description
  -------------------------------------------
  mandatory:
    -d <dir>    $DTEST_SVN_ROOT appserv-tests workspace root
  one of:
    -s <dir>    $GF_SVN_ROOT    GlassFish workspace root
    -g <file>   $GF_ZIP         GlassFish zip distribution to test
                                defaults to: $GF_SVN_ROOT/appserver/distributions/glassfish/target/glassfish.zip
  optional:
    -m <file>   $METRO_ZIP      Metro zip distribution to test
    -w <dir>    $WORK_DIR       working directory
                                defaults to: /tmp
  Note:
    command line options take precedence over environment variables


quicklook.sh -s gfsvnroot [-g glassfish.zip] [-w workingdir] [-m metro.zip]

    unzip GlassFish to workingdir, optionally install Metro on top of it
    and run GlassFish QuickLook test suite

    option      env_var         description
  -------------------------------------------
  mandatory:
    -s <dir>    $GF_SVN_ROOT    GlassFish workspace root containing appserver/tests/quicklook folder
  optional:
    -g <file>   $GF_ZIP         GlassFish zip distribution to test
                                defaults to: $GF_SVN_ROOT/appserver/distributions/glassfish/target/glassfish.zip
    -m <file>   $METRO_ZIP      Metro zip distribution to test
    -w <dir>    $WORK_DIR       working directory
                                defaults to: /tmp
    -p <prof>   $QL_TEST_PROFILE    test profile to run
                                defaults to: all
  Note:
    command line options take precedence over environment variables

