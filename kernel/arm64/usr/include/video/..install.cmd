cmd_usr/include/video/.install := /bin/bash ../scripts/headers_install.sh ./usr/include/video ../include/uapi/video edid.h sisfb.h uvesafb.h; /bin/bash ../scripts/headers_install.sh ./usr/include/video ../include/video ; /bin/bash ../scripts/headers_install.sh ./usr/include/video ./include/generated/uapi/video ; for F in ; do echo "\#include <asm-generic/$$F>" > ./usr/include/video/$$F; done; touch usr/include/video/.install