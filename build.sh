#!/bin/bash

TOPDIR=$(dirname `readlink -f $0`)

if [ "$1" ] ; then
    ARCH=$1
else
    echo  "You must specify the architecture: "
    echo  "please run as: ./build.sh arm |arm64"
    exit
fi
echo ${ARCH}
case ${ARCH} in
	arm)
		CROSS_COMPILE=arm-linux-gnueabihf-
		;;
	arm64)
		CROSS_COMPILE=aarch64-linux-gnu-
		;;
	*)
		echo "Can't find the architecture: ${ARCH}"
		exit 0
		;;
esac

export    ENVDIR=${TOPDIR}/alsa/${ARCH}/usr
export    OUTPUTDIR=${TOPDIR}/output/${ARCH}
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
    find ./* -maxdepth 1 -name "conf*" -type d |xargs rm -rf
    git pull && git checkout .
    cp ${TOPDIR}/patches/default-ddt scenario_groups/default-ddt
    cp ${TOPDIR}/patches/plat/sprd/sharkl3 platforms/sharkl3-sprd
    git am -s < ${TOPDIR}/patches/0001-Fix-open-function-mode-argument-must-be-supplied.patch
    #git am -s < ${TOPDIR}/patches/0001-realtime-clean-up-cpuset-state-after-test-completion.patch

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
