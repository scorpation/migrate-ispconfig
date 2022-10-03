# migrate-ispconfig
MIgrate ISPconfig
This tool helps to migrate a ispconfig server to another server with all dns config, clients, emails, and webpages.

TODO: clients database, properties file,
sed -i 's/OLD_DNS/NEW_DNS/g' /var/named/pri*
sed -i 's/OLD_IP/NEW_IP/g' /var/named/pri*
cp /etc/named.conf.local
