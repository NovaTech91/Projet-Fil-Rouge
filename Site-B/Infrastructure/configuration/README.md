# Configurations Site B

Référence : [SITE_B_Schema.pdf v1.1](../docs/SITE_B_Schema.pdf).
Adressage et câblage : [dossier réseau](../docs/Dossier_reseau.md).

| Fichier | Cible et contenu | Limites |
| --- | --- | --- |
| [SW1.conf](SW1.conf) | Six SVI /27 ; ports d'accès ; port 24 .198/30 ; défaut .197 ; relais DHCP .131 ; ACL Wi-Fi ; sources VTY | Base IOS à adapter au modèle ; console requise ; SSH/AAA à préparer ; matrice des autres VLAN non implémentée dans cet exemple |
| [R1_FW1.md](R1_FW1.md) | Interfaces, routes explicites, NAT, zones et règles | Paramètres à saisir dans TP-Link / StoneOS ; pas un export matériel |
| [Services.md](Services.md) | IP hôtes, DHCP, DNS, proxy et hyperviseurs | Domaine, interfaces système, IP hyperviseur DMZ et secrets à renseigner |
| [DHCP-WIFI.ps1](DHCP-WIFI.ps1) | Création d'une étendue .67-.94/27 inactive, GW .65, DNS .131 | Serveur DHCP installé/autorisé ; refuse d'écraser une étendue existante |
| [Inventaire Ansible](DMZ/Config_Ansible/inventory.ini) | Web1 .80, Web2 .81, Web3 .82 | Les IP /26 et la passerelle .65 doivent déjà être configurées |
| [fronts.yml](DMZ/Config_Ansible/fronts.yml) | Nginx HTTP interne, page et santé, accès HTTP réservé à .72 et localhost | Ne configure pas les IP système ni le pare-feu hôte/SSH |
| [loadbalancer.conf.example](DMZ/loadbalancer.conf.example) | TLS 443 et répartition vers .80-.82:80 | Remplacer domaine et chemins TLS, puis nginx -t ; pas appliqué automatiquement |
| [Mémo DMZ](DMZ/memo_ordre_déploiement.md) | Déploiement et tests positifs/négatifs | Publication 443 en dernier |

Ces fichiers remplacent les paramètres de l'ancien plan, pas une sauvegarde
complète des équipements. Lors d'une migration en place, retirer les anciennes
routes, IP, étendues et ACL après sauvegarde. Les nouvelles ACL doivent remplacer
les anciennes définitions : ne pas fusionner aveuglément deux listes de règles.
Pour SW1, vérifier aussi toutes les plages VTY présentes et leur appliquer
`MGMT_VTY` ; le modèle détermine le nombre de lignes disponibles.

Seul le load balancer `172.16.3.72` reçoit la publication WAN TCP 443.
Aucune publication TCP 80, DNS, SSH ou Proxmox. Les pools disponibles excluent
passerelles, serveurs fixes et réserve hyperviseur. Ne pas activer de DHCP
sur les pools serveurs/DMZ par simple lecture de leur plage disponible.

Les paramètres WAN, modèles, AAA, certificats, domaine, ports de base/Squid,
hébergement de sauvegarde et IP hyperviseur DMZ restent à relever. Aucun
identifiant fictif ni secret n'est intégré. Recette réelle et exports après
validation restent nécessaires.

## Vérifications locales de cette migration

- Onze sous-réseaux contrôlés sans chevauchement ; sept interfaces IP SW1 vérifiées.
- Quinze cas représentatifs évalués sur les règles ordonnées de WIFI_IN : DHCP,
  DNS, diagnostic, retours AP, refus privés et sortie HTTPS.
- Structure YAML du playbook et adresses de l'inventaire vérifiées ; contrôle
  HTTP placé après application des notifications Nginx.
- Syntaxe PowerShell du script DHCP analysée sans erreur ; bornes et exclusions vérifiées.
- Liens Markdown locaux vérifiés, y compris le cahier des charges déplacé dans CDC.

Ces contrôles sont statiques. Ansible et Nginx ne sont pas installés dans
l'environnement de vérification ; `ansible-playbook --syntax-check`, `nginx -t`
et les tests de réseau sont à exécuter sur les systèmes cibles. Les fichiers
n'ont pas été déployés et aucun résultat de recette matérielle n'est déclaré.
