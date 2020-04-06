#!/usr/bin/env bash

CHECK_COMMAND()
{
    if type $1 2>/dev/null; then
        echo "OK"
    else
        echo "FAIL"
    fi
}

INSTALL_BASE_TOOLS()
{
    sudo apt-get update
    sudo apt-get install -y gcc g++ git cmake make automake autoconf pkg-config curl wget libtool libpcre3-dev build-essential
}

INSTALL_FPM()
{
    sudo apt-get install -y ruby ruby-dev rubygems
    sudo gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
    sudo gem sources -l
    sudo gem update --system
    sudo gem install --no-ri --no-rdoc fpm
}

INSTALL_OPENRESTY()
{
    wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    sudo apt-get update
    sudo apt-get -y install software-properties-common
    sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
    sudo apt-get update
    sudo apt-get install -y openresty openresty-resty libpcre3 libpcre3-dev libssl1.0-dev libtool
}

INSTALL_LUAROCKS()
{
    sudo apt-get install luarocks
}

REMOVE_CACHE_PATH()
{
    sudo rm -rf /usr/local/apioak
    sudo rm -rf /tmp/apioak
    sudo rm -rf $1/apioak
}

REMOVE_CACHE_FILE()
{
    sudo rm -rf $1/*.rpm
    sudo rm -rf $1/*.deb
}

BUILD_PACKAGE()
{
    VERSION=$1
    ITERATION=$2
    ABS_PATH=${PWD}

    REMOVE_CACHE_PATH ${ABS_PATH}
    REMOVE_CACHE_FILE ${ABS_PATH}

    git clone -b v${VERSION} https://github.com/apioak/apioak.git
    cd apioak
    sudo luarocks make rockspec/apioak-master-0.rockspec --tree=/usr/local/apioak/deps --local

    sudo mkdir -p /tmp/apioak/usr/local
    sudo mkdir -p /tmp/apioak/usr/bin

    chown -R root:root /usr/local/apioak
    chmod -R 755 /usr/local/apioak

    cp -rf /usr/local/apioak /tmp/apioak/usr/local/
    cp -rf /usr/local/apioak/bin/apioak /tmp/apioak/usr/bin/

    sudo make uninstall
    cd ${ABS_PATH}

    fpm -f -s dir -t deb -n apioak \
        -m 'Janko <shuaijinchao@gmail.com>' \
        -v ${VERSION} \
        --iteration ${ITERATION} \
        --description 'APIOAK is complete lifecycle management API gateway.' \
        --license "Apache License 2.0"  \
        -C /tmp/apioak \
        -p ${ABS_PATH} \
        --url 'https://apioak.com' \
        --deb-no-default-config-files \
        -d 'openresty >= 1.15.8.2' \
        -d 'luarocks >= 2.3.0'

    REMOVE_CACHE_PATH ${ABS_PATH}
}
