#!/bin/bash

echo "Generando el par de llaves para configurar la conexión remota..."
ssh-keygen -f ~/.ssh/ispconfigmigrate
echo ""
echo "Copiando la llave pública al servidor remoto..."
echo "Ingrese los datos del servidor USER@HOST...este USER no debe ser root"
read USER_HOST
ssh-copy-id -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST
echo ""
echo "Respaldando base de datos local..."
echo "Ingrese password ROOT MYSQL local..."
read ROOTMYSQL_PASS_LOCAL
mysqldump -u root -p$ROOTMYSQL_PASS_LOCAL --databases dbispconfig --add-drop-database --events --flush-privileges --hex-blob --lock-tables --routines --set-charset > dbispconfig.sql.respaldo && mysql -u root -p$ROOTMYSQL_PASS_LOCAL -e "DROP DATABASE dbispconfig"
echo ""
echo "Ingrese password ROOT MYSQL remoto"
read ROOTMYSQL_PASS_REMOTO
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "mysqldump -u root -p$ROOTMYSQL_PASS_REMOTO --databases dbispconfig --add-drop-database --events --flush-privileges --hex-blob --lock-tables --routines --set-charset > dbispconfig.sql && tar cfvJ dbispconfig.tar.xz dbispconfig.sql"
echo ""
echo "Copiando base de datos remota a local..."
scp -i ~/.ssh/ispconfigmigrate -P 22 $USER_HOST:dbispconfig.tar.xz ./
echo ""
echo "descomprimiendo base de datos local..."
tar xfvJ dbispconfig.tar.xz
echo ""
echo "instalando base de datos local..."
mysql -u root -p$ROOTMYSQL_PASS_LOCAL < dbispconfig.sql
echo ""
echo "Ingrese password ROOT LINUX Local..."
read ROOT_PASS_LOCAL
echo ""
echo "Ingrese password ROOT LINUX remoto..."
read ROOT_PASS_REMOTO
echo ""
echo "Deteniendo dovecot y postfix...."
echo $ROOT_PASS_LOCAL | su -c "systemctl stop dovecot && systemctl stop postfix"
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"systemctl stop dovecot && systemctl stop postfix\""
echo ""
echo "Comprimiendo archivos de correos...."
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"tar cfvJ email.tar.xz /var/vmail\""
echo ""
echo "Copiando correos remotos a local..."
scp -i ~/.ssh/ispconfigmigrate -P 22 $USER_HOST:email.tar.xz ./
echo ""
echo "descomprimiendo archivos email local..."
echo $ROOT_PASS_LOCAL | su -c "tar xfvJ email.tar.xz -C / && chown vmail:vmail -R /var/vmail"
echo ""
echo ""
echo "Deteniendo APACHE...."
echo $ROOT_PASS_LOCAL | su -c "systemctl stop httpd"
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"systemctl stop httpd\""
echo ""
echo "Comprimiendo archivos DNS...."
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"tar cfvJ dns.tar.xz /var/named/pri*\""
echo ""
echo "Copiando archivos dns remotos a local..."
scp -i ~/.ssh/ispconfigmigrate -P 22 $USER_HOST:dns.tar.xz ./
echo ""
echo "descomprimiendo archivos dns local..."
echo $ROOT_PASS_LOCAL | su -c "tar xfvJ dns.tar.xz -C / && chown named:named -R /var/named && systemctl restart named"
echo ""
echo ""
echo "Comprimiendo archivos html...."
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"rm -f /var/www/clients/client?/web?/log/* && tar cfvJ html.tar.xz /var/www/clients/\""
echo ""
echo "Copiando archivos html remotos a local..."
scp -i ~/.ssh/ispconfigmigrate -P 22 $USER_HOST:html.tar.xz ./
echo ""
echo ""
echo "descomprimiendo archivos html local..."
echo $ROOT_PASS_LOCAL | su -c "tar xfvJ html.tar.xz -C /"
echo ""
echo "creando grupos de linux..."
GRUPOS=$(ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "mysql -u root -p$ROOTMYSQL_PASS_REMOTO -N -e \"select DISTINCT(system_group) from dbispconfig.web_domain\"")

echo $ROOT_PASS_LOCAL | su -c "groupadd sshusers"
for GRUPO in ${GRUPOS}
do
    echo "creando grupo local[$GRUPO]..."
    echo $ROOT_PASS_LOCAL | su -c "groupadd $GRUPO"
    echo $ROOT_PASS_LOCAL | su -c "usermod -a -G $GRUPO apache"
done

echo ""
echo "creando usuarios de linux..."
USUARIOS=$(ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "mysql -u root -p$ROOTMYSQL_PASS_REMOTO -NBe \"select system_user,system_group,domain from dbispconfig.web_domain\"")
while IFS=$'\t' read -r USUARIO GROUP DOMAIN
do
    echo "creando usuario local[$USUARIO][$GROUP][$DOMAIN]..."
    echo $ROOT_PASS_LOCAL | su -c "useradd -d /var/www/clients/$GRUPO/$USUARIO -g $GROUP -G sshusers -M -s /bin/false $USUARIO"
    echo "Asignando permiso a carpetas /var/www/clients/$GROUP/$USUARIO..."
    echo $ROOT_PASS_LOCAL | su -c "chown $USUARIO:$GROUP -R /var/www/clients/$GROUP/$USUARIO/cgi-bin"
    echo $ROOT_PASS_LOCAL | su -c "chown $USUARIO:$GROUP -R /var/www/clients/$GROUP/$USUARIO/private"
    echo $ROOT_PASS_LOCAL | su -c "chown $USUARIO:$GROUP -R /var/www/clients/$GROUP/$USUARIO/.ssh"
    echo $ROOT_PASS_LOCAL | su -c "chown $USUARIO:$GROUP -R /var/www/clients/$GROUP/$USUARIO/tmp"
    echo $ROOT_PASS_LOCAL | su -c "chown $USUARIO:$GROUP -R /var/www/clients/$GROUP/$USUARIO/web"
    echo $ROOT_PASS_LOCAL | su -c "chown $USUARIO:$GROUP -R /var/www/clients/$GROUP/$USUARIO/webdav"
done <<< "${USUARIOS}"

echo ""
echo "Iniciando APACHE...."
echo $ROOT_PASS_LOCAL | su -c "systemctl start httpd"
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"systemctl start httpd\""
echo ""
echo "Iniciando dovecot y postfix...."
echo $ROOT_PASS_LOCAL | su -c "systemctl start dovecot && systemctl start postfix"
ssh -i ~/.ssh/ispconfigmigrate -p 22 $USER_HOST "echo $ROOT_PASS_REMOTO | su -c \"systemctl start dovecot && systemctl start postfix\""
