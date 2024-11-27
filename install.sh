#!/bin/bash

# ============================================================================
# Nom du script : setup_script.sh
# Description   : Script de configuration pour préparer un environnement de 
#                 sauvegarde sécurisé avec FTP et MySQL.
# Auteur        : CineCine86
# Contact       : https://github.com/CineCine86
# Version       : 1.0
# Date          : [Date de création]
# Licence       : MIT License
#
# Copyright (c) 2024 CineCine86
#
# Permission est accordée, sans frais, à toute personne obtenant une copie
# de ce logiciel et des fichiers de documentation associés (le "Logiciel"),
# de traiter le Logiciel sans restriction, y compris, sans s'y limiter,
# les droits d'utiliser, copier, modifier, fusionner, publier, distribuer,
# sous-licencier et/ou vendre des copies du Logiciel, et de permettre
# aux personnes auxquelles le Logiciel est fourni de le faire, sous réserve
# des conditions suivantes :
#
# La notification de copyright ci-dessus et cette notification de
# permission doivent être incluses dans toutes les copies ou parties
# substantielles du Logiciel.
#
# LE LOGICIEL EST FOURNI "EN L'ÉTAT", SANS GARANTIE D'AUCUNE SORTE, EXPLICITE
# OU IMPLICITE, Y COMPRIS MAIS SANS S'Y LIMITER AUX GARANTIES DE
# COMMERCIALISATION, D'ADÉQUATION À UN USAGE PARTICULIER ET D'ABSENCE DE
# CONTREFAÇON. EN AUCUN CAS, LES AUTEURS OU TITULAIRES DU COPYRIGHT NE
# POURRONT ÊTRE TENUS POUR RESPONSABLES DE TOUTE RÉCLAMATION, DOMMAGE OU
# AUTRE RESPONSABILITÉ, QUE CE SOIT DANS UNE ACTION CONTRACTUELLE, DÉLICTUELLE
# OU AUTRE, DÉCOULANT DE, OU EN LIEN AVEC LE LOGICIEL OU L'UTILISATION OU
# D'AUTRES TRAITEMENTS DU LOGICIEL.
#
# Plus d'informations : https://github.com/CineCine86
# ============================================================================

LOG_FILE="/var/log/setup_script.log"
exec > >(tee -a $LOG_FILE) 2>&1

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec les privilèges root. Relancez avec 'sudo'."
    exit 1
fi

# Fonction pour afficher des messages colorés
print_color() {
    local color=$1
    local message=$2
    case $color in
        red) echo -e "\033[1;31m$message\033[0m" ;;
        green) echo -e "\033[1;32m$message\033[0m" ;;
        yellow) echo -e "\033[1;33m$message\033[0m" ;;
        blue) echo -e "\033[1;36m$message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Fonction pour vérifier si un fichier existe
test_file() {
    local source_file=$1
    if [ -f "$source_file" ]; then
        echo "Fichier trouvé : $source_file"
    else
        echo -e "\033[1;5;31mL'installation à déja été effectuer ou les fichiers de configuration sont manquants\033[0m"
        exit 1
    fi
}

# Vérification des fichiers de configuration
test_file "backup_config.conf"
test_file ".my.cnf"

# Configuration des paramètres de sauvegarde
while true; do
    read -p "Souhaitez-vous configurer les paramètres de sauvegarde et d'accès FTP ? (o/n) : " yn
    case $yn in
        [Oo]* ) exec >/dev/tty 2>/dev/tty
		        nano backup_config.conf 
		        exec > >(tee -a $LOG_FILE) 2>&1 
		        ;;
        [Nn]* ) echo "Vous pouvez modifier les paramètres plus tard dans /etc/backup_config.conf"; break ;;
        * ) print_color yellow "Veuillez répondre par 'o' pour Oui ou 'n' pour Non." ;;
    esac
done

# Configuration des paramètres MySQL
while true; do
    read -p "Souhaitez-vous configurer les paramètres de connexion à MySql ? (o/n) : " yn
    case $yn in
        [Oo]* ) exec >/dev/tty 2>/dev/tty
                nano .my.cnf
                exec > >(tee -a $LOG_FILE) 2>&1
                ;;
        [Nn]* ) echo "Vous pouvez modifier les paramètres plus tard dans /root/.my.cnf"; break ;;
        * ) print_color yellow "Veuillez répondre par 'o' pour Oui ou 'n' pour Non." ;;
    esac
done

print_color blue "Vérification des programmes installés"
check_command() {
    command -v $1 >/dev/null 2>&1 || { print_color red "$1 est introuvable. Installation..."; sudo apt install -y $1; }
}
check_command lftp
check_command mail
check_command dos2unix

dos2unix backup_config.conf

print_color green "Attribution des droits d'exécution sur le script de sauvegarde"
if [ -f "serv_backup.sh" ]; then
    sudo chmod +x serv_backup.sh
else
    print_color red "Le script 'serv_backup.sh' est introuvable. Veuillez vérifier."
    exit 1
fi

# Sécurisation des fichiers
secure_file() {
    local source_file=$1
    local dest_file=$2
    local permissions=$3
    if [ -f "$source_file" ]; then
        sudo mv "$source_file" "$dest_file" && echo "Fichier déplacé : $dest_file"
        sudo chmod "$permissions" "$dest_file" && echo "Permissions définies : $permissions pour $dest_file"
    else
        print_color red "Fichier introuvable : $source_file"
    fi
}

secure_file "backup_config.conf" "/etc/backup_config.conf" "600"
secure_file ".my.cnf" "/root/.my.cnf" "600"

print_color green "Configuration des fichiers terminée."

# Exécution du script principal
while true; do
    read -p "Souhaitez-vous exécuter le script de sauvegarde maintenant ? (o/n) : " yn
    case $yn in
        [Oo]* ) ./serv_backup.sh; break ;;
        [Nn]* ) echo "Vous pouvez exécuter le script plus tard avec : ./serv_backup.sh"; break ;;
        * ) print_color yellow "Veuillez répondre par 'o' pour Oui ou 'n' pour Non." ;;
    esac
done

print_color green "Installation et configuration terminées."
exit 0
