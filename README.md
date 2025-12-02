# INSTALLATION ANSIBLE DIRECT SUR LA MACHINE

## Prérequis

- Systèmes d'exploitation supportés : Oracle Linux 7, 8, 9 ou 10
- Droits root requis pour l'exécution des playbooks
- Collections Ansible : `ansible.posix` (installée automatiquement par le script)

Pour Oracle Linux 9 et 10 l'installation Ansible est légèrement différente de Linux 7 ou 8.

Exécuter ce code en tant que root pour installer les préreuis et récupérer les books ansible : 

```bash
#!/bin/bash

# Récupérer la version de la distribution Linux
linux_version=$(cat /etc/os-release | egrep "^VERSION_ID" | cut -d= -f2 | sed 's/"//g' | cut -d. -f1)

# Vérifier la version et exécuter les commandes appropriées
if [[ $linux_version == "7" || $linux_version == "8" ]]; then
    echo "Version Linux 7 ou 8 détectée."
    dnf install -y oracle-epel-release-el${linux_version}
    dnf install -y git ansible
    ansible-galaxy collection install ansible.posix
elif [[ $linux_version == "9" || $linux_version == "10" ]]; then
    echo "Version Oracle Linux 9 ou 10 détectée."
    dnf install -y git ansible-core
    ansible-galaxy collection install ansible.posix
else
    echo "Version Linux non prise en charge détectée."
    exit 1
fi

# cloner le repository :
echo "Récupération du scripts depuis github."
git clone https://github.com/Yacine31/oracle_19_install
```

changement de répertoire
```bash
cd oracle_19_install
```

3 playbooks à utiliser dan l'ordre : 
- oracle-db-preinstall.yml  => configuration de Linux pour une installation Oracle
- oracle-db-install.yml     => installation d'Oracle 19 EE ou SE2 et ajout des scripts d'exploitation
- oracle-db-postinstall.yml  => configuration postinstall : ajout de différents scripts d'exploitation

1. Exécution Pre- install :
```bash
ansible-playbook -i hosts oracle-db-preinstall.yml
```
Parfois ansible ne fonctionne pas sans spécifier le chemin vers python3 : 
```bash
ansible-playbook -i hosts oracle-db-preinstall.yml -e 'ansible_python_interpreter=/usr/bin/python3'
```

2. Exécution Install : installation des binaires Oracle et patch
```bash
ansible-playbook -i hosts oracle-db-install.yml 
```

Les valeurs par défaut : 
```YAML
oracle_version: "19.0.0"
oracle_base: "/u01/app/oracle"
oracle_home: "{{ oracle_base }}/product/{{oracle_version}}/dbhome_1"
oracle_inventory: "/u01/app/oraInventory"
oracle_sources: "/u01/sources"
oracle_oradata: "/u02/oradata/"
oracle_fra: "/u03/fast_recovery_area/"
oracle_install_edition: "EE"               # SE2 (Standard Edition 2) ou EE
```

Pour l'exécuter avec des variables différentes : 

```bash
ansible-playbook -i hosts oracle-db-install.yml --extra-vars "oracle_install_edition=SE2 oracle_version=19c oracle_base=/opt/oracle oracle_home=/opt/oracle/product/19c/dbhome_1"
```

3. Exécution Postinstall : copie des scripts d'exploitation
```bash
ansible-playbook -i hosts oracle-db-postinstall.yml 
```
