#!/bin/bash

TOPDIR=$(dirname `readlink -f $0`)
ARCH=$1
ENVDIR=${TOPDIR}/alsa/${ARCH}/usr
OUTPUTDIR=${TOPDIR}/output/${ARCH}

if [ "${ARCH}" == "arm64" ];then 
    CROSS_COMPILE=aarch64-linux-gnu-
elif [ "${ARCH}" == "arm" ];then
    CROSS_COMPILE=arm-linux-gnueabi-
fi 

export	  ALSA_INCPATH=${ENVDIR}/include
export	  ALSA_LIBPATH=${ENVDIR}/lib

echo $ALSA_INCPATH
echo $ALSA_LIBPATH

function get_ltp-ddt_source_code()
{

    # prepare ddt source code
    if [ ! -d ${TOPDIR}/ltp-ddt ];then
        cd $TOPDIR
        git clone http://arago-project.org/git/projects/test-automation/ltp-ddt.git
    fi
    cd $TOPDIR/ltp-ddt
    git pull && git checkout .
 
    #git am -s < ${TOPDIR}/patches/0001-Fix-open-function-mode-argument-must-be-supplied.patch
    #git am -s < ${TOPDIR}/patches/0001-get_devnode.sh-add-judgment-if-device-not-exist.patch
    #git am -s < ${TOPDIR}/patches/0001-get_modular_config_names.sh-add-hikey-module-name.patch
    #git am -s < ${TOPDIR}/patches/0001-realtime-clean-up-cpuset-state-after-test-completion.patch
    #git am -s < ${TOPDIR}/patches/0001-ddt-uart-Activate-uart-port-before-checking-uartclk.patch
    #git am -s < ${TOPDIR}/patches/0002-ddt-uart-Remove-k-option-from-serialcheck-command-re.patch
    #git am -s < ${TOPDIR}/patches/0003-ddt-uart-Check-test-result-from-receiving-command.patch

}

function compile_ltp-ddt()
{
    cd $TOPDIR/ltp-ddt
    make O=$OUTPUTDIR autotools
    platform_file=hikey
    if [ "${ARCH}" == "arm64" ];then
        platform=aarch64-linux
    elif [ "${ARCH}" == "arm" ];then
        platform=arm-linux
    fi

    # configure
    echo "==== start confirgure===="
    ./configure \
	CC=${CROSS_COMPILE}gcc \
	CROSS_COMPILER=${CROSS_COMPILE}gcc \
	AR=${CROSS_COMPILE}ar \
	STRIP=${CROSS_COMPILE}strip \
	RANLIB=${CROSS_COMPILE}ranlib \
	LD=${CROSS_COMPILE}ld \
	--build=i686-pc-linux-gnu \
	--target=$platform --host=$platform \
	--prefix=$OUTPUTDIR/ltp-ddt
    echo "==== confirgure done ===="
    #make
    echo "==== start make ===="
    make O=$OUTPUTDIR SKIP_IDCHECK=1 \
	KERNEL_INC=${TOPDIR}/kernel/${ARCH}/include \
	KERNEL_USR_INC=${TOPDIR}/kernel/${ARCH}/usr/include \
	PLATFORM=$platform_file clean
    make O=$OUTPUTDIR SKIP_IDCHECK=1 \
	KERNEL_INC=${TOPDIR}/kernel/${ARCH}/include \
	KERNEL_USR_INC=${TOPDIR}/kernel/${ARCH}/usr/include \
	PLATFORM=$platform_file
    #install
    make O=$OUTPUTDIR SKIP_IDCHECK=1 PLATFORM=${platform_file} install
}

get_ltp-ddt_source_code
compile_ltp-ddt
