#!/usr/bin/env bash

# backup current config
if [[ ! -d "${back_up_dir}" ]] ; then
    echo "创建 ${back_up_dir} 目录"
    mkdir ${back_up_dir}
fi

echo ""
echo "备份当前运行的配置信息........"

function getCurrentValue(){
    PARAM_NAME=$1
    current_value=$2

    if [[ ${current_value} ]] ; then
        eval ${PARAM_NAME}=${current_value}
    fi
}
if [[ -e "${v2ray_server_config_file}" ]] ; then
    getCurrentValue V2RAY_TCP_PORT `grep -A 15 'V2RAY_TCP_CONFIG_START' ${v2ray_server_config_file} | grep -w 'port' | grep -v 'V2RAY_TCP_PORT' | tr -d -c '[0-9]'`
    getCurrentValue V2RAY_TCP_UUID `grep -A 15 'V2RAY_TCP_CONFIG_START' ${v2ray_server_config_file} | grep -w 'id' | grep -v 'V2RAY_TCP_UUID' |awk -F ':' '{print $2}'| tr -d -c '[A-Za-z0-9\-]'`

    getCurrentValue V2RAY_WS_PORT `grep -A 15 'V2RAY_TLS_WS_CONFIG_START' ${v2ray_server_config_file}| grep -w 'port' | grep -v 'V2RAY_WS_PORT'| tr -d -c '[0-9]'`
    getCurrentValue V2RAY_WS_UUID `grep -A 15 'V2RAY_TLS_WS_CONFIG_START' ${v2ray_server_config_file} | grep -w "id" | grep -v "V2RAY_WS_UUID"| awk -F ':' '{print $2}'| tr -d -c "[A-Za-z0-9\-]"`
fi

if [[ -e "${compose_file}" ]] ; then
    getCurrentValue CF_MAIL `grep "CLOUDFLARE_EMAIL" ${compose_file} | grep -v "CF_MAIL" | awk -F '=' '{print $2}'`
    getCurrentValue CF_API_KEY `grep "CLOUDFLARE_API_KEY" ${compose_file}| grep -v "CF_API_KEY" | awk -F '=' '{print $2}'`
fi

if [[ -e "${caddy_file}" ]] ; then
    DOMAIN=`head -n 1 ${caddy_file} | grep -v "DOMAIN" |awk '{print $1}'`
fi



printConfig "当前运行配置文件中读取到的配置信息, 写入到 ${config_sh_file} 文件"
writeToConfigSh

if [[ -e "${root_dir}/${config_sh_file}" ]] ; then
    ## 如果 root 目录中的 config.sh 和 backup 中的 config.sh.xxxxx md5 相同，则不需要再备份
    current_md5=`md5sum ${root_dir}/${config_sh_file} | cut -f 1 -d " " `
    latest_backup_md5=`md5sum ${back_up_dir}/$(ls -t ${back_up_dir} | head -n 1) | cut -f 1 -d " "`
    if [[ "${current_md5}" == "${latest_backup_md5}" ]] ; then
        echo "备份已经是最新文件，不用备份"
        return
    fi

    backup_config_sh="${back_up_dir}/${config_sh_file}.`date "+%Y%m%d-%H%M%S"`"
    echo "已经存在 ${root_dir}/${config_sh_file} 文件，备份到 ${back_up_dir}  "
    cp -vf ${root_dir}/${config_sh_file} ${backup_config_sh}
fi

