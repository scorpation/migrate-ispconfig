# migrate-ispconfig
MIgrate ISPconfig<br>
This tool helps to migrate a ispconfig server to another server with all dns config, clients, emails, and webpages.<br>
<br>
TODO: clients database, properties file,<br>
sed -i 's/OLD_DNS/NEW_DNS/g' /var/named/pri*<br>
sed -i 's/OLD_IP/NEW_IP/g' /var/named/pri*<br>
cp /etc/named.conf.local<br>
sudo firewall-cmd --add-port 53/tcp --permanent//BINDNS<br>
sudo firewall-cmd --add-port 53/udp --permanent//BINDNS<br>
sudo firewall-cmd --add-port 25/tcp --permanent//SMTP<br>
sudo firewall-cmd --add-port 143/tcp --permanent//IMAP<br>
sudo firewall-cmd --reload<br>
cp /etc/postfix( sin configuración sql)<br>
cp /etc/mailman( sin configuración sql)<br>
cat "nameserve 8.8.8.8" > /etc/resolv.conf<br>
cat "nameserve 4.4.4.4" > /etc/resolv.conf<br>
