#!/bin/bash

# 压缩日志(主要针对已日期命名的日志)

ARGS=`getopt -a -o l:n:rh -l location:,recursive,name:,help -- "$@"`
[ $? -ne 0 ] && usage

usage() {
    echo "Usage:"
    echo "install.sh "
    echo "Description:"
    echo "-l| --location option set log of the path"
    echo "-n| --name option set the name of the log (regular match the log filename) "
    echo "-r|--recursive option tell program there have mutiple directory need to comparess"
    echo "-h| --help option for get help "
    exit -1
}


comparess() {
    if [[ -z $location && -z $name ]]; then
        echo "please tell me the directry of the location" && exit -1
    fi

    cd $location
    if [[ -z recursive ]];then
        files=`find $location -name $name | grep -Ev $(date '+%d')|tar|gz`
        for f in $files
        do
            file_name=`basename $f`
            tar -czvf $file_name.tar.gz $b && rm -f $file_name
        done
        exit 0
    fi
    files=($(ls $LOCATION |grep -E $name |grep -vE 'tar.gz|zip|gz'|grep -v $(date "+%Y-%m-%d")))
    for f in ${files[@]}
    do
        tar -czvf $f.tar.gz $f
        rm -rf $f
        echo $f
    done
}

eval set -- "${ARGS}"

while true
do
        case "$1" in
        -l|--location)
                location="$2"
                shift
                ;;
        -n|--name)
                name="$2"
                shift
                ;;
        -r|--recursive)
                recursive='yes'
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

comparess
