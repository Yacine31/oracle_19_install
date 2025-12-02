#!/bin/bash
#
# Script d'initialisation pour l'installation Oracle 19 avec Ansible
# Ce script installe les prérequis et clone le repository
#

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage des messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
   log_error "Ce script doit être exécuté en tant que root"
   exit 1
fi

log_info "Démarrage de l'initialisation pour Oracle 19 Installation..."

# Récupérer la version de la distribution Linux
log_info "Détection de la version de Linux..."
linux_version=$(cat /etc/os-release | egrep "^VERSION_ID" | cut -d= -f2 | sed 's/"//g' | cut -d. -f1)

if [[ $linux_version == "7" || $linux_version == "8" ]]; then
    log_info "Version Linux $linux_version détectée - Installation pour OL7/OL8"
    log_info "Installation d'oracle-epel-release-el${linux_version}..."
    dnf install -y oracle-epel-release-el${linux_version}

    log_info "Installation de git et ansible..."
    dnf install -y git ansible

elif [[ $linux_version == "9" || $linux_version == "10" ]]; then
    log_info "Version Oracle Linux $linux_version détectée - Installation pour OL9/OL10"
    log_info "Installation de git et ansible-core..."
    dnf install -y git ansible-core

else
    log_error "Version Linux $linux_version non prise en charge. Versions supportées : Oracle Linux 7, 8, 9, 10"
    exit 1
fi

# Installation de la collection Ansible
log_info "Installation de la collection ansible.posix..."
ansible-galaxy collection install ansible.posix

# Clonage du repository
log_info "Clonage du repository Oracle 19 Installation..."
if [[ -d "oracle_19_install" ]]; then
    log_warning "Le répertoire oracle_19_install existe déjà. Suppression..."
    rm -rf oracle_19_install
fi

git clone https://github.com/Yacine31/oracle_19_install

log_success "Initialisation terminée avec succès !"
log_info ""
log_info "Prochaines étapes :"
log_info "  cd oracle_19_install"
log_info "  # Puis exécuter les playbooks dans l'ordre :"
log_info "  # 1. ansible-playbook -i hosts oracle-db-preinstall.yml"
log_info "  # 2. ansible-playbook -i hosts oracle-db-install.yml"
log_info "  # 3. ansible-playbook -i hosts oracle-db-postinstall.yml"
log_info ""
log_info "Consultez le README.md pour plus de détails."