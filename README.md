# Debian_Backup_WebServ
Description

Le Setup Script est un script Bash open source conçu pour configurer un environnement de sauvegarde sécurisé. Il simplifie la gestion des configurations FTP, MySQL, et la sécurité des fichiers, tout en garantissant une expérience utilisateur intuitive.

Que vous soyez administrateur système ou développeur, ce script vous permet de déployer rapidement et efficacement un environnement de sauvegarde automatisé et sécurisé.

Fonctionnalités

    Vérification et installation des dépendances :
        Assure que tous les outils nécessaires (e.g., lftp, dos2unix, nano) sont installés.
    Configuration intuitive :
        Permet de configurer les paramètres FTP et MySQL via des interfaces interactives.
    Sécurisation des fichiers sensibles :
        Applique automatiquement les permissions adéquates pour protéger vos fichiers de configuration.
    Exécution guidée :
        Propose à l'utilisateur de tester et d'exécuter le script de sauvegarde après l'installation.
    Journalisation détaillée :
        Enregistre toutes les actions dans un fichier de log pour faciliter le débogage.

Prérequis

Avant d'exécuter le script, assurez-vous que votre environnement répond aux exigences suivantes :

    Système d'exploitation : Linux (Debian/Ubuntu recommandé)
    Droits administratifs : Le script doit être exécuté avec sudo.
    Dépendances nécessaires :
        lftp, dos2unix, nano, mysql, et mysqldump

Installation

Clonez le dépôt :

    git clone https://github.com/CineCine86/Debian_Backup_WebServ.git
    cd Debian_Backup_WebServ

Assurez-vous que le script est exécutable :

    chmod +x install.sh

Lancez le script d'installation :

    sudo ./install.sh

Utilisation

    Lors de l'exécution du script, suivez les étapes interactives pour :
        Configurer les paramètres FTP dans backup_config.conf.
        Configurer les paramètres MySQL dans .my.cnf.

    Une fois la configuration terminée, le script propose d'exécuter le script principal de sauvegarde :

    ./serv_backup.sh

    Les journaux sont disponibles dans /var/log/setup_script.log pour déboguer ou auditer les actions réalisées.

Structure du Projet


├── install.sh           # Script principal d'installation

├── serv_backup.sh       # Script de sauvegarde

├── backup_config.conf   # Fichier de configuration FTP

├── .my.cnf              # Fichier de configuration MySQL

└── README.md            # Documentation du projet

Exemple d'utilisation

Voici un exemple de fichier backup_config.conf généré par le script :

    ftp_user="my_ftp_user"
    ftp_password="my_secure_password"
    ftp_server="192.168.1.31"
    ftp_port="990"

Et un exemple de fichier .my.cnf pour MySQL :

    [client]
    user=my_user
    password=my_secure_password

Une fois ces fichiers configurés, le script de sauvegarde peut être exécuté pour transférer vos bases de données et fichiers via FTP.

Contribuer

Les contributions sont les bienvenues ! Pour contribuer :

Forkez le dépôt.
    Créez une branche pour vos modifications :

    git checkout -b feature/ma-fonctionnalite

Testez vos modifications et envoyez une pull request.

Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
Contact

Créé par Cinecine86. Pour toute question ou suggestion :

    Email : yecin.ayache@gmail.com
    GitHub : Cinecine86

