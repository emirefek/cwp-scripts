#!/bin/bash

#if [[ `cat /etc/fstab | grep -E "tmp.*noexec"` != "" ]]; then mount -o remount,exec /tmp >/dev/null 2>&1 ; fi

arch=$(uname -m)
pubip=`curl -s http://centos-webpanel.com/webpanel/main.php?app=showip`
# CONFIGURE MIRRORS HERE
version=2.4.43
opensslver=1.1.1g
openssl_minversion=1.1.1
apachesource="https://downloads.apache.org//httpd/httpd-$version.tar.gz"

# Dependency installer
yum -y install apr-util-devel apr-devel apr apr-util
if [ -f /usr/local/apache/conf/httpd.conf ]; then cp /usr/local/apache/conf/httpd.conf /usr/local/apache/conf/httpd.conf-cwpsave ; fi
test -h /usr/local/src/apache-build || rm -rf /usr/local/src/apache-build
mkdir -p /usr/local/src/apache-build

# OpenSSL Upgrader
if echo -e "$(openssl version|awk '{print $2}')\n${openssl_minversion}" | sort -V | head -1 | grep -q ^${openssl_minversion}$;then
  echo "============================================="
  echo "Your OpenSSL is Up to date. Let's keep going!"
  echo "============================================="
else
  echo "============================================="
  echo "We need to update you OpenSSL for better TLS."
  echo "============================================="
  cd /usr/local/src
	rm -rf openssl-*
	wget https://www.openssl.org/source/openssl-$opensslver.tar.gz
	tar zxvf openssl-$opensslver.tar.gz
	cd openssl-*
	./config --prefix=/usr --openssldir=/usr/lib64 shared
	make && make install
fi

cd /usr/local/src/apache-build
wget -q $apachesource
tar -xf httpd-$version.tar.gz
chown -R root:root httpd-$version/
cd httpd-$version/

# Install Patch - this are patches for version 2.4.26+
wget -q "http://dl1.centos-webpanel.com/files/apache/patch/suexec.patch"
/usr/bin/patch -p1 < suexec.patch

#rm -f /usr/local/apache/conf/httpd.conf
./configure --enable-so --prefix=/usr/local/apache --enable-unique-id --enable-ssl=shared --enable-rewrite --enable-deflate --enable-suexec --with-suexec-docroot=/home --with-suexec-caller=nobody --with-suexec-logfile=/usr/local/apache/logs/suexec_log --enable-asis --enable-filter --with-pcre --with-apr=/usr/bin/apr-1-config --with-apr-util=/usr/bin/apu-1-config --enable-headers --enable-expires --enable-proxy --enable-rewrite --enable-userdir --enable-brotli --with-brotli=/usr

configurecheck=$?
if [ $configurecheck -eq 0 ];then
        rm -f /usr/local/apache/conf/httpd.conf
fi

make clean

if [ -e "/usr/bin/nproc" ];then
	make -j `/usr/bin/nproc`
else
	make
fi
make install

mkdir /usr/local/apache/conf.d
touch /usr/local/apache/conf.d/empty.conf
# Check if lines below already added and add those if wasn't added before.
if [[ "`grep ExtendedStatus /usr/local/apache/conf/httpd.conf 2>/dev/null`" == "" ]]; then
echo "ExtendedStatus On" >> /usr/local/apache/conf/httpd.conf
echo "Include /usr/local/apache/conf/sharedip.conf" >> /usr/local/apache/conf/httpd.conf
echo "Include /usr/local/apache/conf.d/*.conf" >> /usr/local/apache/conf/httpd.conf
fi
# Check if installed nginx/varnish.
if [[ "`grep ':8181' /usr/local/apache/conf.d/vhosts.conf 2> /dev/null`" != "" ]]; then
        sed -i "s/^.*Listen 80$/Listen 8181/" /usr/local/apache/conf/httpd.conf
        sed -i "s/:80/:8181/" /usr/local/apache/conf/sharedip.conf
fi
sed -i "s|DirectoryIndex index.html|DirectoryIndex index.php index.html index.htm|g" /usr/local/apache/conf/httpd.conf
sed -i "0,/^\([[:blank:]]*\)DirectoryIndex.*$/ s//\1 DirectoryIndex index.html.var index.htm index.html index.shtml index.xhtml index.wml index.perl index.pl index.plx index.ppl index.cgi index.jsp index.js index.jp index.php4 index.php3 index.php index.phtml default.htm default.html home.htm index.php5 Default.html Default.htm home.html/" /usr/local/apache/conf/httpd.conf


cat > /usr/local/apache/conf/sharedip.conf <<EOF
<VirtualHost $pubip:80>
    ServerName $pubip
    DocumentRoot /usr/local/apache/htdocs
    ServerAdmin info@centos-webpanel.com
    <IfModule mod_suphp.c>
        suPHP_UserGroup nobody nobody
    </IfModule>
    <Proxy "*">
        <IfModule mod_security2.c>
            SecRuleEngine Off
        </IfModule>
    </Proxy>
    RewriteEngine On
    RewriteCond %{HTTP_HOST} !^$pubip\$
    RewriteCond %{HTTP_HOST} ^webmail.
    RewriteRule ^/(.*) http://%{HTTP_HOST}:2095/\$1 [P]
</VirtualHost>
<Directory "/">
        AllowOverride All
        Require all granted
</Directory>
EOF

sed -i "s|User daemon|User nobody|g" /usr/local/apache/conf/httpd.conf
sed -i "s|Group daemon|Group nobody|g" /usr/local/apache/conf/httpd.conf
sed -i "s|.*modules/libphp5.so.*||g" /usr/local/apache/conf/httpd.conf
sed -i "s|.*httpd-userdir.conf.*|Include conf/extra/httpd-userdir.conf|" /usr/local/apache/conf/httpd.conf
sed -i "s|#LoadModule userdir_module modules.*$|LoadModule userdir_module modules/mod_userdir.so|" /usr/local/apache/conf/httpd.conf
sed -i "s|#LoadModule unique_id_module modules.*$|LoadModule unique_id_module modules/mod_unique_id.so|" /usr/local/apache/conf/httpd.conf
sed -i "s|#LoadModule rewrite_module modules.*$|LoadModule rewrite_module modules/mod_rewrite.so|" /usr/local/apache/conf/httpd.conf
sed -i "s|#LoadModule proxy_module modules.*$|LoadModule proxy_module modules/mod_proxy.so|" /usr/local/apache/conf/httpd.conf
sed -i "s|#LoadModule proxy_connect_module modules.*$|LoadModule proxy_connect_module modules/mod_proxy_connect.so|" /usr/local/apache/conf/httpd.conf
sed -i "s|#LoadModule proxy_http_module modules.*$|LoadModule proxy_http_module modules/mod_proxy_http.so|" /usr/local/apache/conf/httpd.conf

mkdir -p /usr/local/apache/conf.d

cd /usr/local/apache/bin/
ldconfig

#ADDITIONAL_CONFIGURATION
if [ ! -e "/usr/local/apache/conf.d/domain-redirects.conf" ];then
cat > /usr/local/apache/conf.d/domain-redirects.conf <<EOF
RewriteEngine on
Alias /phpmyadmin /usr/local/apache/htdocs/phpMyAdmin
Alias /phpMyAdmin /usr/local/apache/htdocs/phpMyAdmin
Alias /webmail /usr/local/apache/htdocs/roundcube
Alias /WebMail /usr/local/apache/htdocs/roundcube
Alias /roundcube /usr/local/apache/htdocs/roundcube
EOF
fi

cat > /usr/local/apache/conf.d/system-redirects.conf <<EOF
Redirect permanent /phpmyadmin https://$pubip:2031/pma
Redirect permanent /phpMyAdmin https://$pubip:2031/pma
Redirect permanent /cwp https://$pubip:2083/
Redirect permanent /cwpadmin https://$pubip:2031/
EOF

if [[ ! -z "`grep ':8181' /usr/local/apache/conf.d/vhosts/*.conf 2> /dev/null`" ]]; then
        sed -i "s/^.*Listen 80$/Listen 8181/" /usr/local/apache/conf/httpd.conf
        sed -i "s/:80/:8181/" /usr/local/apache/conf/sharedip.conf
fi

if [[ ! -e "/usr/local/apache/conf.d/vhosts/" ]]; then
        mkdir /usr/local/apache/conf.d/vhosts/
fi

if [[ ! -e "/usr/local/apache/domlogs/" ]]; then
        mkdir /usr/local/apache/domlogs/
fi

if [ ! -e "/usr/local/apache/conf.d/vhosts.conf" ];then
       cat > /usr/local/apache/conf.d/vhosts.conf <<EOF
IncludeOptional /usr/local/apache/conf.d/vhosts/*.conf
EOF
fi

if [[ -z `grep "LogFormat.*\"%b\".*bytes" /usr/local/apache/conf/httpd.conf` ]];then
        sed -i '0,/    LogFormat/s//    LogFormat \"%b\" bytes\n&/' /usr/local/apache/conf/httpd.conf
        sed -i "s/LogFormat \"%h/LogFormat \"%a/g" /usr/local/apache/conf/httpd.conf
fi

if [[ ! -z `grep "you@example.com" /usr/local/apache/conf/httpd.conf` ]];then
        sed -i 's/you@example.com/root@localhost/g' /usr/local/apache/conf/httpd.conf
fi

# Brotli Compression Enabler #
touch /usr/local/apache/conf.d/brotli.conf
cat > /usr/local/apache/conf.d/brotli.conf <<EOF
LoadModule brotli_module modules/mod_brotli.so
<IfModule mod_brotli.c>
BrotliCompressionQuality 6

# To enable globally 
AddOutputFilterByType BROTLI_COMPRESS text/html text/plain text/xml text/css text/javascript application/x-javascript application/javascript application/json application/x-font-ttf application/vnd.ms-fontobject image/x-icon

BrotliFilterNote Input brotli_input_info
BrotliFilterNote Output brotli_output_info
BrotliFilterNote Ratio brotli_ratio_info
LogFormat '"%r" %{brotli_output_info}n/%{brotli_input_info}n (%{brotli_ratio_info}n%%)' brotli
CustomLog "logs/brotli_log" brotli
#Don't compress content which is already compressed
SetEnvIfNoCase Request_URI \
\.(gif|jpe?g|png|swf|woff|woff2) no-brotli dont-vary
#Make sure proxies don't deliver the wrong content
Header append Vary User-Agent env=!dont-vary
</IfModule>
EOF


service httpd restart
echo "Apache Rebuild Completed"
echo
echo
#if [[ `cat /etc/fstab | grep -E "tmp.*noexec"` != "" ]]; then mount -o remount /tmp >/dev/null 2>&1 ; fi

# Add alert info into cwp
#sh /scripts/add_alert alert-info "Apache Re-Build task completed, please check the log for more details." /var/log/apache-rebuild.log
/usr/local/cwp/php71/bin/php /usr/local/cwpsrv/htdocs/resources/admin/include/libs/notifications/cli.php --level="info" --subject="Apache Re-Build INFO" --message="Apache Re-Build task completed, please check the log for more details. Click <a title='Apache Re-Build task LOG' href='index.php?module=file_editor&file=/var/log/apache-rebuild.log'>here</a> to check it."

test -h /usr/local/src/apache-build || rm -Rf /usr/local/src/apache-build
rm -rf /usr/local/src/apache-rebuild.sh
