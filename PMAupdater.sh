#!/bin/bash

current_version=`cat /usr/local/cwpsrv/var/services/pma/README | grep Version | cut -d " " -f 2`
pma_latest=`curl -Ss "https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/STABLE/README" | grep Version | cut -d " " -f 2`

if [ "$current_version" != "$pma_latest" ];then
        echo "Updating phpMyAdmin from ${current_version} to version ${pma_latest}"
        Date=`date "+%d-%m-%Y"`

        if [ -e "/usr/local/cwpsrv/var/services/pma" ];then
                mv /usr/local/cwpsrv/var/services/pma /usr/local/cwpsrv/var/services/pma_$Date.bak
        fi

        cd /usr/local/cwpsrv/var/services/
        wget https://files.phpmyadmin.net/phpMyAdmin/${pma_latest}/phpMyAdmin-${pma_latest}-all-languages.zip
        unzip -o -q phpMyAdmin-${pma_latest}-all-languages.zip
        rm -f phpMyAdmin-${pma_latest}-all-languages.zip
        mv phpMyAdmin-${pma_latest}-all-languages pma
        chown -R cwpsvc:cwpsvc pma
        rm -rf /usr/local/cwpsrv/var/services/pma/setup
        mv /usr/local/cwpsrv/var/services/pma/config.sample.inc.php /usr/local/cwpsrv/var/services/pma/config.inc.php
        ran_password=$(</dev/urandom tr -dc A-Za-z0-9 | head -c32)
        sed -i "s|\['blowfish_secret'\] = ''|\['blowfish_secret'\] = '${ran_password}'|" /usr/local/cwpsrv/var/services/pma/config.inc.php
        new_version=`cat /usr/local/cwpsrv/var/services/pma/README | grep Version | cut -d " " -f 2`
        echo "phpMyAdmin Updated to: latest stable version ${new_version}"
        echo "This script will be maintaned by emirefek.net you can find updated version from GitHub always!"
        echo "#######           github.com/emirefek/cwp-scripts         #######"
else
        echo "Looks like you already have the latest PMA version recommended by PhpMyAdmin Creators! We didn't upgraded anything."
        echo "This script is maintaning by emirefek.net and if you sure there is newer verison of PMA and if it is still rejects to update please update script from the GitHub URL below!"
        echo "#######           github.com/emirefek/cwp-scripts         #######"
fi
