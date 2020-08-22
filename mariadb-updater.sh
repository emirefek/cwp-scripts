#!/bin/bash
echo "#######################################"
echo "      CWP MariaDB Upgrade Script       "
echo "#######################################"

arch=$(uname -m)
pubip=`curl -s http://centos-webpanel.com/webpanel/main.php?app=showip`
hostname=`cat /etc/hostname`
mariadb_current=`/usr/bin/mysql -V | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+'`
mariadb_latest=10.5.5
mariadb_repo=http://yum.mariadb.org/10.5/centos7-amd64/

pma_current=`cat /usr/local/cwpsrv/var/services/pma/README | grep Version | cut -d " " -f 2`
pma_latest=`curl -Ss "https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/STABLE/README" | grep Version | cut -d " " -f 2`

centosversion=`rpm -qa \*-release | grep -Ei "oracle|redhat|centos|cloudlinux" | cut -d"-" -f3|head -n 1`

if [ "$centosversion" != "6" ]; then

    if [ "$mariadb_current" != "$mariadb_latest" ];then
		mkdir /home/mariadb_backup
		cd /home/mariadb_backup
		echo "########################################"
		echo "   MariaDB Backing up with compression  "
		echo "########################################"
		for I in $(mysql -e 'show databases' -s --skip-column-names); do mysqldump $I | gzip > "$I.sql.gz"; done
		echo "#########################################"
		echo "Backup Completed You can find backups in:"
		echo "           /home/mariadb_backup          "
		echo ""
		echo "  Let's Keep going with MariaDB upgrade  "
		echo "#########################################"

		rm -rf /etc/my.cnf.bak-updater
		cp /etc/my.cnf /etc/my.cnf.bak-updater

			if [ ${pma_current} '<' '5.6' ]; then
				service mariadb stop
				service mysql stop
				/bin/rpm -e --nodeps galera
				/usr/bin/yum remove -y mariadb mariadb-server
			else
				service mysql stop 
				/bin/rpm -e --nodeps galera
				/usr/bin/yum remove -y MariaDB-server MariaDB-client
			fi
		
		/usr/bin/yum install -y nano epel-release
		mv /etc/yum.repos.d/mariadb.repo /etc/yum.repos.d/mariadb.repo.bak
		cat > /etc/yum.repos.d/mariadb.repo <<EOF
[mariadb]
name = MariaDB
baseurl = $mariadb_repo
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
		/usr/bin/yum clean all
		/usr/bin/yum install -y MariaDB-server MariaDB-client net-snmp perl-DBD-MySQL
		/usr/bin/yum update -y
		rm -rf /etc/my.cnf
		cp /etc/my.cnf.bak-updater /etc/my.cnf

		systemctl enable mariadb
		service mysql start
		mysql_upgrade
mariadb_upgraded=`/usr/bin/mysql -V | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+'`
		echo "#############################################"
		echo "MariaDB Upgrade Done New Version: $mariadb_upgraded"
		echo "You can find backups in:/home/mariadb_backup"
		echo "#############################################"
    else
		echo "#######################################"
		echo "     MariaDB is already up to date    "
		echo "     Let's skip updateing script      "
		echo "#######################################"
	fi

	if [ "$pma_current" != "$pma_latest" ];then
		echo "#######################################"
		echo "        PhpMyAdmin is outdated.        "
		echo "           Let's update it             "
		echo "#######################################"
		cd /tmp
		wget --no-cache https://raw.githubusercontent.com/emirefek/cwp-scripts/master/pma-updater.sh
		chmod 755 pma-updater.sh
		sh pma-updater.sh
		cd /tmp
		rm -f pma-updater.sh
	else
		echo "#######################################"
		echo "       PhpMyAdmin is up to date.       "
		echo "        Everything should fine.        "
		echo "#######################################"
    fi

else
	echo "#######################################"
	echo "      Your are running CentOS 6        "
	echo "     I'm just supporting CentOS 7      "
	echo "#######################################"
fi
