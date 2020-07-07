
# Scripts for Centos Web Panel

***apache-updater.sh***
Updater Apache to latest + updater to OpenSSL + enabler brotli + TLSv1.3 enabler [All thanks goes to [mysterydata.com](https://www.mysterydata.com/install-latest-apache-version-in-cwp-control-web-panel/), I just did small mods]

    ### HOW TO USE apache-updater.sh ###
    
    cd /usr/local/src
    rm -rf /usr/local/src/apache*
    wget --no-cache  https://raw.githubusercontent.com/emirefek/cwp-scripts/master/apache-updater.sh
    chmod 755 apache-updater.sh
    sh apache-updater.sh
