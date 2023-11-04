# core3566-yocto
Trying to start yocto on core3566

```
git clone -b master https://git.yoctoproject.org/poky
git clone -b master https://git.openembedded.org/meta-openembedded
git clone -b master https://git.yoctoproject.org/meta-arm

source poky/oe-init-build-env .

bitbake core-image-minimal
```