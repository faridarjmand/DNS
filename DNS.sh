#!/bin/bash

# This Script use for Auto Create DNS

##############################
########## Variable ##########
##############################

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

##############################
########## Functions #########
##############################

check ()
{
        if [ "$?" == "0" ];then
                echo -e ${green}"Done"${nc}
        else
                echo -e ${red}"Error"${nc}
		exit
        fi
}

get ()
{
	i=0
	while true;do
		read -p "Do you want to add TLD (com,net,org) ?(y/n): " tld
		if [ "$tld" == "y" ];then
			mkdir /var/www/html/$domain-$tld
			echo "<h1>This is Test $domain.$tld</h1>" > /var/www/html/$domain-$tld/index.html
			echo -e """<VirtualHost $ip:80>\nServerName $domain.$tld\nServerAlias www.$domain.$tld\nDocumentRoot /var/www/html/$domain-$tld\n</VirtualHost>""" >> /etc/sysconfig/httpd
			echo -e """$ip	www.$domain.$tld	$domain.$tld""" >> /etc/hosts
			i=$((i+1))
		elif [ "$tld" == "n" ];then
			break
		else
			clear
			echo -e ${red}"Try Again !!\n"${nc}
		fi
	done
}

##############################
############ Main ############
##############################

clear

read -p "Please Enter your Domain (facebook) : " domain
read -p "Please Enter your IP (127.0.0.1) : " ip


if [ -z "$domain" ];then
	domain="$USER"
fi
if [ -z "$ip" ];then
	ip="127.0.0.1"
fi

yum -y install bind bind-chroot caching-nameserver
check
service httpd restart
check
service named start
check


# Create named.conf
echo -e """options {
directory \"/var/named\";
};
zone \"$domain.com\" {
type master;
file \"$domain.com.db\";
};""" > /etc/named.conf
check


# Create domain.db
echo -e """\$TTL	86400
$domain.com.		IN SOA ns1.$domain.com.       root (
					42		; serial (d. adams)
					3H		; refresh
					15M		; retry
					1W		; expiry
					1D )		; minimum

	        IN NS		@
	 	IN A		$ip
		IN AAAA		::1
www		IN A		$ip
ns1		IN A		$ip""" > /var/named/$domain.com.db
check


service named stop
check


lsattr /etc/resolv.conf
chattr -a /etc/resolv.conf
lsattr /etc/resolv.conf
chattr -i /etc/resolv.conf
lsattr /etc/resolv.conf
echo "nameserver $ip" > /etc/resolv.conf
chattr +i /etc/resolv.conf
check


service named start
check




service httpd start
check


echo -e """Your Domain = ${green}\"$domain.com\"${nc}    and    Your IP = ${green}\"$ip\"${nc}
Your Domain = ${green}\"$domain.org\"${nc}    and    Your IP = ${green}\"$sysip\"${nc}"""

#############################
############ END ############
#############################