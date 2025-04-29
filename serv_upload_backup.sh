#!/bin/bash

# Importer les variables du fichier de configuration
source /etc/backup_config.conf

# Définition des chemins
LOG_FILE="/var/log/lftp_backup.log"
TEMP_DIR="/tmp/backup_$(date +"%Y-%m-%d_%H-%M-%S")"
CURRENT_DATE="$(date +"%Y-%m-%d_%H-%M-%S")"

# Fonction pour envoyer un e-mail en cas d'échec
send_error_email() {
    local message=$1
    echo -e "Subject: [ERREUR] Backup BDD

$message" | mail -s "Backup BDD Failed" "$EMAIL_TO"
}

# Fonction pour envoyer un e-mail en cas de succès
send_success_email() {
    local message=$1
    echo -e "Subject: [SUCCES] Backup BDD

$message" | mail -s "Backup BDD Successful" "$EMAIL_TO"
}

# Log début du script
echo "[$(date)] Début du script de backup." >> "$LOG_FILE"

# 1. Vérification de la connectivité au serveur FTP (test du port, pas de ping)
echo "[$(date)] Test de connectivité FTP sur $ftp_server:$ftp_port..." >> "$LOG_FILE"
nc -zvw5 "$ftp_server" "$ftp_port" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[$(date)] Erreur : Port FTP ($ftp_port) injoignable sur $ftp_server." >> "$LOG_FILE"
    send_error_email "Impossible de joindre le port $ftp_port du serveur FTP : $ftp_server"
    exit 1
fi

echo "[$(date)] Port FTP accessible." >> "$LOG_FILE"

# 2. Vérification des permissions d'écriture sur /tmp
echo "[$(date)] Vérification des permissions d'écriture sur /tmp..." >> "$LOG_FILE"
touch /tmp/test_write_permissions.txt > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[$(date)] Erreur : Pas de permissions sur /tmp." >> "$LOG_FILE"
    send_error_email "Pas de permissions d'écriture dans /tmp."
    exit 1
fi
rm /tmp/test_write_permissions.txt

echo "[$(date)] Permissions sur /tmp OK." >> "$LOG_FILE"

# 3. Extraction de la liste des bases de données
echo "[$(date)] Récupération de la liste des bases de données..." >> "$LOG_FILE"
DATABASES=$(mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

if [ -z "$DATABASES" ]; then
    echo "[$(date)] Erreur : Aucune base de données à sauvegarder." >> "$LOG_FILE"
    send_error_email "Aucune base de données disponible pour la sauvegarde."
    exit 1
fi

echo "[$(date)] Bases de données trouvées : $DATABASES" >> "$LOG_FILE"

# 4. Création du dossier temporaire
echo "[$(date)] Création du dossier temporaire $TEMP_DIR..." >> "$LOG_FILE"
mkdir -p "$TEMP_DIR"

# 5. Sauvegarde de chaque base de données
for DB in $DATABASES; do
    SQL_DUMP_FILE="$TEMP_DIR/$DB-$CURRENT_DATE.sql"
    echo "[$(date)] Sauvegarde de la base $DB vers $SQL_DUMP_FILE..." >> "$LOG_FILE"
    mysqldump "$DB" > "$SQL_DUMP_FILE"
    if [ $? -ne 0 ]; then
        echo "[$(date)] Erreur : Échec de sauvegarde de $DB." >> "$LOG_FILE"
        send_error_email "Échec de la sauvegarde de la base $DB."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    echo "[$(date)] Sauvegarde de $DB réussie." >> "$LOG_FILE"
done

# 6. Transfert FTP
echo "[$(date)] Début du transfert FTP..." >> "$LOG_FILE"

lftp -d -u "$ftp_user","$ftp_password" -p "$ftp_port" ftps://$ftp_server -e "
set ftp:ssl-force true;
set ftp:ssl-protect-data true;
set ssl:verify-certificate no;
set ftp:passive-mode true;
set ftp:ssl-allow true;
set ftp:ssl-protect-list yes;
cd SAUVEGARDE/PROD/UPLOADS;
mkdir -p $CURRENT_DATE;
cd $CURRENT_DATE;
mirror -R $local_upload_folder ./local_upload_folder
mirror -R $TEMP_DIR ./databases;
bye
" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "[$(date)] Erreur : Échec du transfert FTP." >> "$LOG_FILE"
    send_error_email "Échec du transfert des bases de données vers le serveur FTP."
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "[$(date)] Transfert FTP réussi." >> "$LOG_FILE"

# 7. Nettoyage
echo "[$(date)] Nettoyage du dossier temporaire..." >> "$LOG_FILE"
rm -rf "$TEMP_DIR"

# 8. Notification de succès
echo "[$(date)] Envoi de l'e-mail de succès..." >> "$LOG_FILE"
send_success_email "Le transfert des bases de données vers le serveur FTP a réussi."

# 9. Nettoyage des variables sensibles
unset ftp_password
unset ftp_user
unset DB
unset DATABASES

# 10. Fin du script
echo "[$(date)] Script de backup terminé avec succès." >> "$LOG_FILE"

exit 0
