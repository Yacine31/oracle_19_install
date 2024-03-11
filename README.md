# INSTALLATION ANSIBLE DIRECT SUR LA MACHINE

```bash
dnf install -y oracle-epel-release-el8
dnf install -y git ansible
dnf install -y python3-libselinux
```

```bash
ansible-galaxy collection install ansible.posix 
```
=> sinon les modules ne sont pas reconnus par ansible

# cloner le repository :
(compte root)
```bash
git clone https://github.com/Yacine31/oracle_19_install
cd oracle_19_install
```

2 books à jour : 
- oracle-db-preinstall.yml  => configuration de Linux pour une installation Oracle
- oracle-db-install.yml     => installation d'Oracle 19 EE ou SE et ajout des scripts d'exploitation

1. Exécution Pre- install :
```bash
ansible-playbook -i hosts oracle-db-preinstall.yml -e 'ansible_python_interpreter=/usr/bin/python3'
```

2. Exécution Install :
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
oracle_install_edition: "EE"               # SE2 ou EE
```


Pour l'exécuter avec des variables différentes : 

```bash
ansible-playbook -i hosts oracle-db-install.yml --extra-vars "oracle_install_edition=SE oracle_version=19c oracle_base=/opt/oracle oracle_home=/opt/oracle/product/19c/dbhome_1"
```