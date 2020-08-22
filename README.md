
# Scripts for Centos Web Panel

***apache-updater.sh***
Updater Apache to latest + updater to OpenSSL + enabler brotli + TLSv1.3 enabler [All thanks goes to [mysterydata.com](https://www.mysterydata.com/install-latest-apache-version-in-cwp-control-web-panel/), I just did small mods]

    ### HOW TO USE apache-updater.sh ###
    
    wget --no-cache  https://raw.githubusercontent.com/emirefek/cwp-scripts/master/apache-updater.sh
    chmod 755 apache-updater.sh
    sh apache-updater.sh

***pma-updater.sh***
Updater for PhpMyAdmin to latest recommendated stable version by PhpMyAdmin Team rather than CWP Team, CWP team is just ignores security updates and with this script you can update PhpMyAdmin to latest [Thanks to [CWP Team](http://centos-webpanel.com/) for  base script, I just did some mods in it.]

    ### HOW TO USE pma-updater.sh ###
    
    wget --no-cache  https://raw.githubusercontent.com/emirefek/cwp-scripts/master/pma-updater.sh
    chmod 755 pma-updater.sh
    sh pma-updater.sh
