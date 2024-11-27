#!/bin/bash

# Importer les variables du fichier de configuration
source /etc/backup_config.conf

echo $ftp_server
echo $ftp_port


# Définition des variables
current_date=$(date +"%Y-%m-%d_%H-%M-%S")
local_folder="/var/www/"
EMAIL_TO=""

# Fonction pour envoyer une notification par e-mail en cas d'échec
send_error_email() {
    local message=$1
    echo -e "Subject: Backup Failed\n\n$message" | mail -s "Backup Failed" $EMAIL_TO
}

# Fonction pour envoyer une notification par e-mail en cas de succès
send_success_email() {
    local message=$1
    echo -e "Subject: Backup Successful\n\n$message" | mail -s "Backup Succesful" $EMAIL_TO
}

# Vérification de la connectivité réseau
ping -c 1 $ftp_server > /dev/null 2>&1
if [ $? -ne 0 ]; then
    send_error_email "Impossible de joindre le serveur FTP : $ftp_server"
    exit 1
fi

# Vérification des permissions d'écriture dans le répertoire temporaire
touch /tmp/test_write_permissions.txt > /dev/null 2>&1
if [ $? -ne 0 ]; then
    send_error_email "Pas de permissions d'écriture dans le répertoire /tmp"
    exit 1
fi
rm /tmp/test_write_permissions.txt

# Vérification si le dossier local existe
if [ ! -d "$local_folder" ]; then
    send_error_email "Le dossier local à copier n'existe pas : $local_folder"
    exit 1
fi

# Obtenir la liste des bases de données
DATABASES=$(mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

# Création d’un répertoire temporaire pour les sauvegardes
TEMP_DIR="/tmp/backup_$current_date"
mkdir -p $TEMP_DIR

# Sauvegarder chaque base de données
for DB in $DATABASES; do
    SQL_DUMP_FILE="$TEMP_DIR/$DB-$current_date.sql"
    mysqldump $DB > $SQL_DUMP_FILE
    if [ $? -ne 0 ]; then
        send_error_email "Échec de la sauvegarde de la base de données : $DB"
        rm -rf $TEMP_DIR
        exit 1
    fi
done

# Transfert des fichiers via FTP
lftp -d -u $ftp_user,$ftp_password ftps://$ftp_server:$ftp_port <<EOF
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:verify-certificate no
mkdir $current_date
cd $current_date
mirror -R $local_folder ./local_folder
mirror -R $TEMP_DIR ./databases
bye
EOF

if [ $? -ne 0 ]; then
    send_error_email "Échec du transfert des fichiers sur le serveur FTP."
    rm -rf $TEMP_DIR
    exit 1
fi

# Nettoyage des fichiers temporaires
rm -rf $TEMP_DIR

# Envoyer un e-mail de succès
send_success_email "Le transfert des fichiers et des bases de données vers le serveur FTP a réussi."

# Nettoyer les variables sensibles
unset DB_PASSWORD
unset FTP_PASSWORD

exit 0
