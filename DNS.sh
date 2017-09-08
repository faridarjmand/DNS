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

start ()
{
	service $1 start
	check
}

stop ()
{
	service $1 stop
	check
}

restart ()
{
	service $1 restart
	check
}

install ()
{
	yum -y install httpd bind bind-chroot caching-nameserver openssl
	check
	restart httpd
}

domain ()
{
	read -p "Please Enter your Domain (facebook) : " domain
	read -p "Please Enter your TLD : " domain_tld
	read -p "Please Enter your IP (127.0.0.1) : " ip
	if [ -z "$domain" ];then
		domain="$USER"
	fi
	if [ -z "$ip" ];then
		ip="127.0.0.1"
	fi
	check
}

virtual_hosting ()
{
	i=0
	while true;do
		read -p "Do you want to add TLD ?(y/n): " tld
		if [ "$tld" == "y" ];then
			mkdir /var/www/html/$domain-$tld
			echo "<h1>This is Test $domain.$tld</h1>" > /var/www/html/$domain-$tld/index.html
			echo -e """<VirtualHost $ip:80>\nServerName $domain.$tld\nServerAlias www.$domain.$tld\nDocumentRoot /var/www/html/$domain-$tld\n</VirtualHost>""" >> /etc/httpd/conf/httpd.conf
			echo -e """$ip	www.$domain.$tld	$domain.$tld""" >> /etc/hosts
			check
			i=$((i+1))
		elif [ "$tld" == "n" ];then
			break
		else
			clear
			echo -e ${red}"Try Again !!\n"${nc}
		fi
	done
	check
}

resolv ()
{
	lsattr /etc/resolv.conf
	chattr -a /etc/resolv.conf
	lsattr /etc/resolv.conf
	chattr -i /etc/resolv.conf
	lsattr /etc/resolv.conf
	echo "nameserver $ip" > /etc/resolv.conf
	chattr +i /etc/resolv.conf
	check
	start named
	start httpd
}

https ()
{
	read -p "Do you want SSL ?(y/n): " ssl
		if [ "$ssl" == "y" ];then
			openssl genrsa -des3 -out /etc/httpd/conf/server.key 1024
			openssl req -new -key server.key -out server.csr
			openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
			vim /etc/httpd/conf.d/ssl.conf
			restart httpd
		elif [ "$tld" == "n" ];then
			break
		else
			clear
			echo -e ${red}"Try Again !!\n"${nc}
		fi
	check
}

named_conf ()
{
start named
echo -e """options {
directory \"/var/named\";
};
zone \"$domain.$domain_tld\" {
type master;
file \"$domain.$domain_tld.db\";
};""" > /etc/named.conf
check
}

domain_db ()
{
echo -e """\$TTL	86400
$domain.$domain_tld.		IN SOA ns1.$domain.$domain_tld.       root (
					42		; serial (d. adams)
					3H		; refresh
					15M		; retry
					1W		; expiry
					1D )		; minimum

	        IN NS		@
	 	IN A		$ip
		IN AAAA		::1
www		IN A		$ip
ns1		IN A		$ip""" > /var/named/$domain.$domain_tld.db
check
stop named
}

end ()
{
echo -e """Your Domain = ${green}\"$domain.com\"${nc}    and    Your IP = ${green}\"$ip\"${nc}
Your Domain = ${green}\"$domain.org\"${nc}    and    Your IP = ${green}\"$sysip\"${nc}"""
}

##############################
############ Main ############
##############################

clear
domain
install
named_conf
domain_db
resolv
https

end

#############################
############ END ############
#############################
