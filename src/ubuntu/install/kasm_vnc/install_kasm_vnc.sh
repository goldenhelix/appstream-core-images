#!/usr/bin/env bash
set -e

echo "Install KasmVNC server"
cd /tmp
if [ "${DISTRO}" == "kali" ]  ;
then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/bcad19542e02921f1f275532cc7854559d737cb5/kasmvncserver_kali-rolling_0.9.3_master_bcad19_amd64.deb"
elif [ "${DISTRO}" == "centos" ] ; then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/bcad19542e02921f1f275532cc7854559d737cb5/output/centos_core/kasmvncserver-0.9.1~beta-1.el7.x86_64.rpm"
else
    UBUNTU_CODENAME=$(grep -Po -m 1 "(?<=_CODENAME=)\w+" /etc/os-release)
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/bcad19542e02921f1f275532cc7854559d737cb5/kasmvncserver_${UBUNTU_CODENAME}_0.9.3_master_bcad19_amd64.deb"
fi


if [ "${DISTRO}" == "centos" ] ; then
    wget $BUILD_URL -O kasmvncserver.rpm

    yum localinstall -y kasmvncserver.rpm
    rm kasmvncserver.rpm
else
    wget $BUILD_URL -O kasmvncserver.deb

    apt-get update
    apt-get install -y gettext ssl-cert
    dpkg -i /tmp/kasmvncserver.deb
    apt-get -yf install
    rm -f /tmp/kasmvncserver.deb
fi
#mkdir $KASM_VNC_PATH/certs
mkdir -p $KASM_VNC_PATH/www/Downloads
chown -R 0:0 $KASM_VNC_PATH
chmod -R og-w $KASM_VNC_PATH
#chown -R 1000:0 $KASM_VNC_PATH/certs
chown -R 1000:0 $KASM_VNC_PATH/www/Downloads
ln -s $KASM_VNC_PATH/www/index.html $KASM_VNC_PATH/www/vnc.html
