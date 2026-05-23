#!/bin/bash
#
# Script d'initialisation pour l'installation Oracle 19c/26ai avec Ansible
# Ce script installe les prérequis et clone le repository
#

set -eo pipefail  # Arrêter sur erreur et sur échec dans un pipe

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_info "Démarrage de l'initialisation pour installation Oracle 19c/26ai ..."

# Récupérer la version de la distribution Linux
log_info "Détection de la version de Linux..."
linux_version=$(grep -E "^VERSION_ID" /etc/os-release | cut -d= -f2 | sed 's/"//g' | cut -d. -f1)

if [[ $linux_version == "7" || $linux_version == "8" ]]; then
    log_info "Version Oracle Linux $linux_version détectée - Installation pour OL7/OL8"
    log_info "Installation d'oracle-epel-release-el${linux_version}..."
    dnf install -y oracle-epel-release-el${linux_version}
    log_info "Installation de git et ansible..."
    dnf install -y git ansible

elif [[ $linux_version == "9" || $linux_version == "10" ]]; then
    log_info "Version Oracle Linux $linux_version détectée - Installation pour OL9/OL10"
    log_info "Installation de git et ansible-core..."
    dnf install -y git ansible-core

else
    log_error "Version Linux '$linux_version' non prise en charge. Versions supportées : Oracle Linux 7, 8, 9, 10"
    exit 1
fi

# Installation de la collection Ansible
# --ignore-certs nécessaire si le proxy d'entreprise intercepte le trafic HTTPS
log_info "Installation de la collection ansible.posix..."
ansible-galaxy collection install ansible.posix --ignore-certs

# Clonage du repository
log_info "Clonage du repository oracle_19_install..."
if [[ -d "oracle_19_install" ]]; then
    backup="oracle_19_install.bak.$(date +%Y%m%d_%H%M%S)"
    log_warning "Le répertoire oracle_19_install existe déjà. Renommage en ${backup}..."
    mv oracle_19_install "$backup"
fi

git clone https://github.com/Yacine31/oracle_19_install

# Copie du fichier de mot de passe vault dans le répertoire home de root
log_info "Configuration du mot de passe Ansible Vault..."
cp oracle_19_install/.vault_pass ~/.vault_pass
chmod 600 ~/.vault_pass

log_success "Initialisation terminée avec succès !"
log_info ""
log_info "Mots de passe par défaut :"
log_info "  - Utilisateur oracle  : Oracle123"
log_info "  - Utilisateur grid    : Grid123"
log_info "  - Mot de passe vault  : Oracle123"
log_info ""
log_info "Pour changer les mots de passe oracle/grid :"
log_info "  cd oracle_19_install"
log_info "  ansible-vault edit group_vars/vault.yml"
log_info "  # Modifier vault_oracle_user_password et vault_grid_user_password"
log_info ""
log_info "Pour changer le mot de passe vault :"
log_info "  ansible-vault rekey group_vars/vault.yml"
log_info "  echo 'NouveauMotDePasse' > ~/.vault_pass"
log_info ""
log_info "Exécuter les playbooks dans l'ordre :"
log_info "  cd oracle_19_install"
log_info "  ansible-playbook -i hosts oracle-db-preinstall.yml"
log_info "  ansible-playbook -i hosts oracle-db-install.yml"
log_info "  ansible-playbook -i hosts oracle-db-postinstall.yml"
log_info ""
log_info "Consultez le README.md pour plus de détails."
