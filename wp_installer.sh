#!/bin/bash -e

if [[ $EUID -ne 0 ]]; then
   echo -e "You Must be Root User to run this!!" 1>&2
   exit 1
fi
echo "[+]IT WILL REMOVE EVERYTHING INSIDE /var/www/http/"
echo "Your Root Password: "
read -s rootpass
echo "Password For WordPress database: "
read -s dbpass
echo "Start? (Y/N)"
read -e begin
if [ "$begin" == n/N ] ; then
exit
else
apt update 	
apt install apache2 -y
clear
#mv /etc/apache2/mods-enabled/dir.conf /etc/apache2/mods-enabled/dir_conf_original
#cd /etc/apache2/mods-enabled
#echo '''<IfModule mod_dir.c>\n	DirectoryIndex index.php index.cgi index.pl index.html index.xhtml index.htm\n</IfModule>\n\n# vim: syntax=apache ts=4 sw=4 sts=4 sr noet'''  > dir.conf
systemctl start apache2
systemctl enable apache2
apt install perl php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl mariadb-server -y
systemctl start mysql.service
systemctl enable mysql.service
mysql -u root -p$rootpass -Bse "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -u root -p$rootpass -Bse "GRANT ALL ON wordpress.* TO 'wp_user'@'localhost' IDENTIFIED BY '$dbpass';"
mysql -u root -p$rootpass -Bse "FLUSH PRIVILEGES;"
clear
cd /var/www/html/
rm -rf *
curl -O https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz
cd wordpress
cp -rf . ..
cd ..
rm -R wordpress
cp wp-config-sample.php wp-config.php
perl -pi -e "s/database_name_here/wordpress/g" wp-config.php
perl -pi -e "s/username_here/wp_user/g" wp-config.php
perl -pi -e "s/password_here/$dbpass/g" wp-config.php
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php
mkdir wp-content/uploads
chmod 775 wp-content/uploads
cd /var/www/html/
rm latest.tar.gz
fi
clear
