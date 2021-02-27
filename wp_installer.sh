#!/bin/bash -e
# Author - Krishna Kumar
# This script is for new users who wants to simplify the installation process od Wordpress.
# Tested on Ubuntu and Debian (Don't Work on Arch Linux.)
# Must Run as a root User.  

banner(){
	clear
	echo -e \e[36m '
                       _                         
__      _____  _ __ __| |_ __  _ __ ___  ___ ___ 
\ \ /\ / / _ \| '__/ _` | '_ \| '__/ _ \/ __/ __|
 \ V  V / (_) | | | (_| | |_) | | |  __/\__ \__ \
  \_/\_/ \___/|_|  \__,_| .__/|_|  \___||___/___/
                        |_|                      
			
 _           _        _ _           
(_)_ __  ___| |_ __ _| | | ___ _ __ 
| | '_ \/ __| __/ _` | | |/ _ \ '__|
| | | | \__ \ || (_| | | |  __/ |   
|_|_| |_|___/\__\__,_|_|_|\___|_|   
                                    			

'
}


root(){
	if [[ $EUID -ne 0 ]]
	then
		echo -e "\n\n\n\n[+] Run it as a root user.\n" 1>&2
		exit 1
	fi	
}



cred(){
	read -s -p "[>>]Your Root Password: " rootpass
	echo ''
	read -s -p "[>>]Password For WordPress database: " dbpass
	echo ''
	read -p "[>>]Start? (Y/N): " begin
	echo ''
}

echo ">>> IT WILL REMOVE EVERYTHING INSIDE /var/www/http/"

start(){
	if [[ "$begin" == n/N ]]; then
		exit
	else 
#Install package		
		apt update 
		apt install apache2 perl php tar figlet libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl mariadb-server -y
#Start Server
		systemctl enable apache2
		systemctl start apache2
		systemctl disable mysql.service
		systemctl enable mysql.service
		systemctl start mysql.service
		
#Making SQL Database
		mysql -u root -p$rootpass -Bse "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
		mysql -u root -p$rootpass -Bse "GRANT ALL ON wordpress.* TO 'wp_user'@'localhost' IDENTIFIED BY '$dbpass';"
		mysql -u root -p$rootpass -Bse "FLUSH PRIVILEGES;"
#Installing wordpress
		cd /var/www/html/
		rm -rf *
		curl -O https://wordpress.org/latest.tar.gz
		tar -zxvf latest.tar.gz	
		rm latest.tar.gz
		cp -rf wordpress/* . 
		rm -rf wordpress
#Wordpress Configs
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
#Giving upload directory Permissions
		mkdir wp-content/uploads
		chmod 775 wp-content/uploads
		clear	
	fi		
}

end(){
	ip=$(ip a | grep "inet 192." | cut -d " " -f 6 | cut -d "/" -f 1)
	echo -e "[+] Wordpress Successfully Installed.\n"
	echo -e "[>>>]You can See you Wordpress site at http://$ip/\n\n"
}

#MarCus
banner
root
cred
start
banner
end
