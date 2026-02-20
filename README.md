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

**3 playbooks à utiliser dan l'ordre :**

| Rôle                     | Tâche                                               |
|--------------------------|-----------------------------------------------------|
| oracle-db-preinstall.yml | configuration de Linux pour une installation Oracle |
| oracle-db-install.yml    | installation d'Oracle 19c/26ai EE ou SE2 et application du dernier patch RU |
| oracle-db-postinstall.yml | configuration postinstall : ajout de différents scripts d'exploitation |

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

## Configuration des variables

Toutes les variables communes sont centralisées dans `group_vars/all.yml` pour éviter la duplication :

```yaml
# Variables communes Oracle (group_vars/all.yml)
oracle_version: "19.0.0"
oracle_base: "/u01/app/oracle"
dbhome: "dbhome_1"
oracle_home: "{{ oracle_base }}/product/{{oracle_version}}/{{ dbhome }}"
# exemple :
# oracle_home: "/u01/app/oracle/product/19.0.0/dbhome_1"
oracle_inventory: "/u01/app/oraInventory"
oracle_sources: "/u01/sources"
oracle_oradata: "/u02/oradata/"
oracle_fra: "/u03/fast_recovery_area/"

# Variables de configuration
full_configuration: true
secure_configuration: false
scripts_dir: "/home/oracle/scripts"

# Mots de passe utilisateurs système (en clair - seront hashés automatiquement)
oracle_user_password: "Oracle123"
grid_user_password: "Grid123"

# Variables spécifiques au rôle d'installation (roles/oracle-db-install/defaults/main.yml)
oracle_install_edition: "EE"   # SE2 (pour Standard Edition 2)
oracle_zip_filename: "Oracle_Database_19.3.0.0.0_for_Linux_x86-64.zip"
```

## Personnalisation des variables

### Important : Configuration des mots de passe utilisateurs

**Avant de lancer `oracle-db-preinstall.yml`, vous devez configurer les mots de passe des utilisateurs système :**

```bash
# Éditer le fichier des variables
vi group_vars/all.yml
```

```bash
# Modifier les mots de passe (valeurs par défaut) :
oracle_user_password: "VotreMotDePasseOracle"
grid_user_password: "VotreMotDePasseGrid"
```

**Note :** Les mots de passe sont stockés en clair dans le fichier mais seront automatiquement hashés (SHA-512) lors de la création des utilisateurs.

### Modification des variables communes

Pour modifier les variables communes (dans `group_vars/all.yml`) :

```bash
# Éditer le fichier des variables communes
vi group_vars/all.yml
```

```bash
# Exemple de personnalisation :
oracle_base: "/opt/oracle"
oracle_version: "19.3.0"
scripts_dir: "/home/oracle/custom_scripts"
```

### Variables spécifiques aux rôles

Chaque rôle peut avoir ses propres variables dans `roles/<role>/defaults/main.yml`.

### Surcharge via la ligne de commande

Pour surcharger temporairement des variables :

```bash
# Exemple pour installer SE2 au lieu d'EE
ansible-playbook -i hosts oracle-db-install.yml --extra-vars "oracle_install_edition=SE2"

# Exemple avec un oracle_base personnalisé
ansible-playbook -i hosts oracle-db-install.yml --extra-vars "oracle_base=/opt/oracle"
```

3. Exécution Postinstall : copie des scripts d'exploitation
```bash
ansible-playbook -i hosts oracle-db-postinstall.yml
```

## Structure du projet

```
oracle_19_install/
├── group_vars/
│   └── all.yml                       # Variables communes à tous les rôles
├── roles/
│   ├── oracle-db-preinstall/         # Configuration système pré-installation
│   │   ├── defaults/main.yml         # Variables spécifiques au rôle
│   │   ├── tasks/
│   │   │   ├── main.yml              # Tâches principales
│   │   │   ├── validations.yml       # Validations préalables
│   │   │   └── [autres fichiers...]
│   │   └── templates/                # Templates Jinja2
│   ├── oracle-db-install/            # Installation des binaires Oracle
│   └── oracle-db-postinstall/        # Configuration post-installation
│       ├── handlers/main.yml         # Gestionnaires d'événements
│       └── tasks/
│           ├── scripts.yml           # Gestion des scripts
│           ├── backup.yml            # Configuration sauvegardes
│           └── services.yml          # Services système
├── init_oracle_install.sh            # Script d'initialisation
├── hosts                             # Inventaire Ansible
├── oracle-db-*.yml                   # Playbooks principaux
└── README.md                         # Cette documentation
```
