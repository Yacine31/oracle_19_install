# Installation Oracle 19c ou 26ai avec Ansible

## Prérequis

- Systèmes d'exploitation supportés : Oracle Linux 7, 8, 9 ou 10
- Droits root requis pour l'exécution des playbooks
- Collections Ansible : `ansible.posix` (installée automatiquement par le script)

## Initialisation rapide

Pour Oracle Linux 9 et 10, l'installation Ansible est légèrement différente de Linux 7 ou 8.

**Méthode recommandée :** Utilisez le script d'initialisation fourni

```bash
# Télécharger et exécuter le script d'initialisation (en tant que root)
curl -fsSL https://raw.githubusercontent.com/Yacine31/oracle_19_install/main/init_oracle_install.sh | bash
```

Puis changer de répertoire :
```bash
cd oracle_19_install
```

**3 playbooks à utiliser dans l'ordre :**

| Rôle                      | Tâche                                                                          |
|---------------------------|--------------------------------------------------------------------------------|
| oracle-db-preinstall.yml  | configuration de Linux pour une installation Oracle                            |
| oracle-db-install.yml     | installation d'Oracle 19c/26ai EE ou SE2 et application du dernier patch RU (19c uniquement) |
| oracle-db-postinstall.yml | configuration postinstall : ajout de différents scripts d'exploitation         |

## Execution des rôles Ansible

1. Exécution du playbook Pre-install :

```bash
# IMPORTANT : Configurez d'abord les mots de passe et les chemins dans group_vars/all.yml
ansible-playbook -i hosts oracle-db-preinstall.yml
ansible-playbook -i hosts oracle-db-preinstall.yml -e 'oracle_version=19c'
ansible-playbook -i hosts oracle-db-preinstall.yml -e 'oracle_version=26ai'
```

**Par défaut**, si `oracle_version` n'est pas spécifiée, c'est la version **19c** qui sera installée

Parfois ansible ne fonctionne pas sans spécifier le chemin vers python3 :

```bash
ansible-playbook -i hosts oracle-db-preinstall.yml -e 'ansible_python_interpreter=/usr/bin/python3'
```

2. Exécution du playbook Install : installation des binaires Oracle et patch
```bash
ansible-playbook -i hosts oracle-db-install.yml
ansible-playbook -i hosts oracle-db-install.yml -e 'oracle_version=26ai'
```

3. Exécution Postinstall : copie des scripts d'exploitation
```bash
ansible-playbook -i hosts oracle-db-postinstall.yml
```

## Configuration des variables

Toutes les variables communes sont centralisées dans `group_vars/all.yml` :

```yaml
# Version Oracle à installer : "19c" ou "26ai"
oracle_version: "19c"

oracle_base: "/u01/app/oracle"
dbhome: "dbhome_1"
# oracle_home est construit automatiquement :
# /u01/app/oracle/product/19.0.0/dbhome_1  (pour 19c)
# /u01/app/oracle/product/23.0.0/dbhome_1  (pour 26ai)

oracle_inventory: "/u01/app/oraInventory"
oracle_sources: "/u01/sources"
oracle_oradata: "/u02/oradata/"
oracle_fra: "/u03/fast_recovery_area/"

full_configuration: true
secure_configuration: false
scripts_dir: "/home/oracle/scripts"

# Mots de passe utilisateurs système (en clair - seront hashés automatiquement)
oracle_user_password: "Oracle123"
grid_user_password: "Grid123"

# Édition Oracle : "EE" (Enterprise Edition) ou "SE2" (Standard Edition 2)
oracle_install_edition: "EE"
```

Les variables spécifiques à chaque version (binaires, patches) sont dans `roles/oracle-db-install/vars/19c.yml` et `vars/26ai.yml`.

> **Note :** Le patch Release Update (RU) n'est appliqué que pour la version **19c**. La version **26ai** installe uniquement les binaires de base.

## Personnalisation des variables

### Important : Configuration des mots de passe utilisateurs

**Avant de lancer `oracle-db-preinstall.yml`, vous devez configurer les mots de passe des utilisateurs système :**

```bash
vi group_vars/all.yml
```

```yaml
oracle_user_password: "VotreMotDePasseOracle"
grid_user_password: "VotreMotDePasseGrid"
```

**Note :** Les mots de passe sont stockés en clair dans le fichier mais seront automatiquement hashés (SHA-512) lors de la création des utilisateurs.

### Modification des variables communes

```bash
vi group_vars/all.yml
```

```yaml
# Exemple : installer Oracle 26ai avec un oracle_base personnalisé
oracle_version: "26ai"
oracle_base: "/opt/oracle"
scripts_dir: "/home/oracle/custom_scripts"
```

### Variables spécifiques aux rôles

Chaque rôle peut avoir ses propres variables dans `roles/<role>/defaults/main.yml`.

### Surcharge via la ligne de commande

```bash
# Exemple pour installer SE2 au lieu d'EE
ansible-playbook -i hosts oracle-db-install.yml --extra-vars "oracle_install_edition=SE2"

# Exemple avec un oracle_base personnalisé
ansible-playbook -i hosts oracle-db-install.yml --extra-vars "oracle_base=/opt/oracle"
```

## Structure du projet

```
oracle_19_install/
├── group_vars/
│   └── all.yml                        # Variables communes à tous les rôles
├── roles/
│   ├── oracle-db-preinstall/          # Configuration système pré-installation
│   │   ├── tasks/                     # os, grub, réseau, sécurité, utilisateurs
│   │   └── vars/
│   │       ├── main.yml               # Variables communes (sysconfig, seclimits, services)
│   │       └── RedHat_{7,8,9,10}.yml  # Packages spécifiques à chaque version OS
│   ├── oracle-db-install/             # Installation des binaires Oracle
│   │   ├── tasks/install-db.yml       # Tâches communes 19c/26ai (patch RU : 19c uniquement)
│   │   └── vars/
│   │       ├── 19c.yml                # URLs et fichiers pour Oracle 19c
│   │       └── 26ai.yml               # URLs et fichiers pour Oracle 26ai
│   └── oracle-db-postinstall/         # Configuration post-installation
│       └── tasks/                     # scripts, backup, services, validations
├── init_oracle_install.sh             # Script d'initialisation
├── hosts                              # Inventaire Ansible
├── oracle-db-*.yml                    # Playbooks principaux
└── README.md                          # Cette documentation
```
