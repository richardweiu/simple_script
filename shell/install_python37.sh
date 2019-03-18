#!/bin/bash

# TODO:
# 1、python 的版本写死了，没有办法指定版本安装了
# 2、解决 openssl 链接库替换不干净的问题

# 运行流程
# 1、安装相关依赖（openssl 用源码安装的 lib 库曾经尝试会替换不干净）
#   1.1 判断是否用代理
#   1.2 添加阿里云原
#   1.3 安装相关依赖
# 2、下载源码、编译、软连接
# 3、配置
# 4、清理战场

URL='https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz'
HOME=$(env |grep -w HOME | awk -F '=' '{print $2}')
ARGS=`getopt -a -o u:d:ih -l user:,datebase:,internal,help -- "$@"`

usage() {
    echo "Usage:"
    echo "install.sh "
    echo "Description:"
    echo "-u| --user option set user for add some config if without this option use current user"
    echo "-i| --internal option for tell program this enviroment just internal or can view internet"
    echo "-d| --datebase option for install which datebase, default install mysql"
    echo "-h| --help option for get help "
    exit -1
}

install_dependency() {
    if [[ $INTERNAL == 'yes' ]]; then
        # 这里当时没有用 nc 或 telnet 检测服务是否工作的原因是：并不是所有的机器都预装有 nc 与 telnet，curl 一般是必带所以这样操作
        curl 10.16.194.19:3128 || (echo "This proxy service maybe break" && exit -1)
        export http_proxy=10.16.194.19:3128
    fi

    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && yum makecache
    yum -y install gcc-c++ openssl-devel zlib-devel libffi-devel readline-devel bzip2-devel ncurses-devel sqlite-devel gdbm-devel xz-devel tk-devel libuuid-devel libpcap-devel db4-deve nginx

    if [[ -z $db ]];then
        yum install -y mariadb-libs mysql-devel
    else
        # yum install -y postgresql
        yum install -y $db
    fi
}

build_python() {
    cd /tmp/
    wget $URL
    tar -xzvf Python-3.7.2.tgz
    cd Python-3.7.2
    ./configure --prefix=/usr/local/python3
    ./configure --enable-optimizations
    make && make install
    ln -s /usr/local/python3/bin/python3.7 /usr/bin/python3
    ln -s /usr/local/python3/bin/pip3.7 /usr/bin/pip3
}

add_config() {
    if [[ -z $user ]];then
        cd $HOME
    else
        HOME=$(cat /etc/passwd |grep -w $user | awk -F ':' '{print $(NF-1)}')
        cd $HOME
    fi
    if ! [[ -e $HOME"/.pip" ]]; then
        mkdir $HOME/.pip
    fi

    if [[ -z $INTERNAL ]]; then
        echo -e '[global]\nindex-url = http://jfrog.cloud.qiyi.domain/api/pypi/pypi/simple\ntrusted-host = jfrog.cloud.qiyi.domain\ndisable-pip-version-check = true' > $HOME/.pip/pip.conf;
    else
        echo -e '[global]\nindex-url = https://mirrors.aliyun.com/pypi/simple/\ntrusted-host = mirrors.aliyun.com\ndisable-pip-version-check = true' > $HOME/.pip/pip.conf;
    fi
}

remove() {
    rm -rf /etc/yum.repos.d/CentOS-Base.repo
    cd ~ && rm -rf /tmp/Python-3.7.2
}

[ $? -ne 0 ] && usage
eval set -- "${ARGS}"

while true
do
        case "$1" in
        -u|--user)
                user="$2"
                shift
                ;;
        -d|--datebase)
                db="$2"
                shift
                ;;
        -i|--internal)
                URL='http://10.16.194.19:808/log/Python-3.7.2.tgz'
                INTERNAL=yes
                ;;
        -h|--help)
                usage
                ;;
        --)
                shift
                break
                ;;
        esac
shift
done

install_dependency
build_python
add_config
remove
