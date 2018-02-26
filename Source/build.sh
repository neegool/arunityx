#! /bin/bash

#
# Build artoolkitX for all platforms.
#
# Copyright 2018, artoolkitX Contributors.
# Author(s): Thorsten Bux <thor_artk@outlook.com> , Philip Lamb <phil@artoolkitx.org>
#

# Get our location.
OURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ARUNITYX_HOME=$OURDIR/..

if [ $# -eq 0 ]; then
    echo "Must specify platform to build. One or more of: macos, ios, linux, android."
    exit 1
fi

# -e = exit on errors
set -e -x

# Parse parameters
while test $# -gt 0
do
    case "$1" in
        macos) BUILD_MACOS=1
            ;;
        ios) BUILD_IOS=1
            ;;
        linux) BUILD_LINUX=1
            ;;
        android) BUILD_ANDROID=1
            ;;
        windows) BUILD_WINDOWS=1
            ;;
        --debug) DEBUG=
            ;;
        --*) echo "bad option $1"
            usage
            ;;
        *) echo "bad argument $1"
            usage
            ;;
    esac
    shift
done

# Set OS-dependent variables.
OS=`uname -s`
ARCH=`uname -m`
TAR='/usr/bin/tar'
if [ "$OS" = "Linux" ]
then
    CPUS=`/usr/bin/nproc`
    TAR='/bin/tar'
    # Identify Linux OS. Sets useful variables: ID, ID_LIKE, VERSION, NAME, PRETTY_NAME.
    source /etc/os-release
    # Windows Subsystem for Linux identifies itself as 'Linux'. Additional test required.
    if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null ; then
        OS='Windows'
    fi
elif [ "$OS" = "Darwin" ]
then
    CPUS=`/usr/sbin/sysctl -n hw.ncpu`
elif [ "$OS" = "CYGWIN_NT-6.1" ]
then
    # bash on Cygwin.
    CPUS=`/usr/bin/nproc`
    OS='Windows'
elif [ "$OS" = "MINGW64_NT-10.0" ]
then
    # git-bash on Windows.
    CPUS=`/usr/bin/nproc`
    OS='Windows'
else
    CPUS=1
fi

if [ "$OS" = "Darwin" ] ; then
# ======================================================================
#  Build platforms hosted by macOS
# ======================================================================

# macOS
# Locate ARTOOLKITX_HOME or clone into submodule
    if [ ! -f "$OURDIR/Extras/artoolkitx/LICENSE.txt" ] && [ -z $ARTOOLKITX_HOME ]; then
        echo "artoolkitX not found. Please set ARTOOLKITX_HOME or clone submodule"

        read -p "Would you like to use the submodule (recommended) y/n" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            git submodule init
            git submodule update --remote
        else
            echo "Build failed!, Exit"
            exit 1;
        fi
    fi

    #Set ARTOOLKITX_HOME for internal use
    #Are we using the submodule?
    if [  -f "$OURDIR/Extras/artoolkitx/LICENSE.txt" ] && [ -z $ARTOOLKITX_HOME ]; then
        ARTOOLKITX_HOME=$OURDIR/Extras/artoolkitx
    fi

    #Android
    if [ $BUILD_ANDROID ] ; then 
        #Empty the existing plugin directory
        rm -f $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/armeabi-v7a/libc++_shared.so
        rm -f $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/armeabi-v7a/libARX.so
        rm -f $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/x86/libc++_shared.so
        rm -f $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/x86/libARX.so
        rm -f $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/arxjUnity.jar
        rm -f $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/arunityXPlayer-release.aar

        #Build arxjUnity.jar
        cd $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj
        ./gradlew :ARXJ:jarReleaseUnity
        #copy arxjUnity.jar into plugins directory and into arunityXPlayer project to make the project compileable
        cp $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj/arxj/build/libs/arxjUnity.jar $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/
        cp $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj/arxj/build/libs/arxjUnity.jar $ARUNITYX_HOME/Source/Extras/arunityx_java/arunityX_Android_Player/arunityXPlayer/arxjUnity/

        #Copy the native libraries into the Plugin directory. They are build as part of the .jar build
        cp $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj/arxj/build/intermediates/bundles/release/jni/armeabi-v7a/libc++_shared.so $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/armeabi-v7a/
        cp $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj/arxj/build/intermediates/bundles/release/jni/armeabi-v7a/libARX.so $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/armeabi-v7a/
        cp $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj/arxj/build/intermediates/bundles/release/jni/x86/libc++_shared.so $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/x86/
        cp $ARTOOLKITX_HOME/Source/ARXJ/ARXJProj/arxj/build/intermediates/bundles/release/jni/x86/libARX.so $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/libs/x86/

        #Build arunityXPlayer
        cd $ARUNITYX_HOME/Source/Extras/arunityx_java/arunityX_Android_Player/
        ./gradlew :arunityXPlayer:assembleRelease
        #Copy to plugins directory
        cp $ARUNITYX_HOME/Source/Extras/arunityx_java/arunityX_Android_Player/arunityXPlayer/build/outputs/aar/arunityXPlayer-release.aar $ARUNITYX_HOME/Source/Package/Assets/Plugins/Android/
    fi

    if [ $BUILD_MACOS ] ; then
        #Start ARToolKitX macOS build
        cd $ARTOOLKITX_HOME/Source
        ./build.sh macos

        #Make sure we remove the AR6.bundle first and then copy the new one in
        rm -rf $ARUNITYX_HOME/Source/Package/Assets/Plugins/ARX.bundle
        cp -rf $ARTOOLKITX_HOME/SDK/Plugins/ARX.bundle $ARUNITYX_HOME/Source/Package/Assets/Plugins/
    fi
fi
            