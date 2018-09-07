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


# prepare ddt source code
if [ ! -d ${TOPDIR}/ltp-ddt ];then
    cd $TOPDIR
    git clone http://arago-project.org/git/projects/test-automation/ltp-ddt.git
fi
cd $TOPDIR/ltp-ddt
git pull && git checkout .
#cd  $TOPDIR/ltp-ddt/testcases/ddt/alsa_test_suite/src/testcases
#sed -i 's/O_CREAT/O_CREAT,0666/g' st_alsa_capture_file_test.c
#cd $TOPDIR/ltp-ddt/testcases/ddt/filesystem_test_suite/src/testcases/
#sed -i 's/O_CREAT/O_CREAT,0666/g' st_filesystem_copy_file.c
#cd $TOPDIR/ltp-ddt/testcases/ddt/filesystem_test_suite/src/testcases/
#sed -i 's/O_CREAT/O_CREAT,0666/g' st_filesystem_write_to_file.c
cd $TOPDIR/ltp-ddt 
#rm testcases/ddt/ipc_test_suite -r

## git apply patch 
cd $TOPDIR/ltp-ddt 
git reset --hard 831ed83e49df467fb4a7d7ac00b1ae3c5e6961be
git am -s < ${TOPDIR}/patches/0001-st_filesystem_write_to_file.c-when-has-O_CREAT-the-t.patch
git am -s < ${TOPDIR}/patches/0001-st_filesystem_copy_file.c-when-has-O_CREAT-the-third.patch
git am -s < ${TOPDIR}/patches/0001-st_alsa_capture_file_test.c-when-has-O_CREAT-the-thi.patch
git am -s < ${TOPDIR}/patches/0001-get_modular_config_names.sh-add-hikey-module-name.patch
git am -s < ${TOPDIR}/patches/0001-common.sh-modify-LTPPATH.patch
git am -s < ${TOPDIR}/patches/0001-get_devnode.sh-add-judgment-if-device-not-exist.patch

 
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

