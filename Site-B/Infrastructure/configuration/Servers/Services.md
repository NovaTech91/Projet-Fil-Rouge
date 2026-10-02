# Paramètres des hôtes et services

Référence : [plan complet des hôtes](../docs/Dossier_reseau.md#3-hôtes-réservations-et-pools).
Les noms d'interfaces Linux/Windows sont à relever avant de modifier une IP.
Sauvegarder la configuration et prévoir une console hyperviseur.

## Hyperviseurs, VM et clients

- Proxmox Dell interne : pont non étiqueté vers SW1 port 22, `172.16.1.130/27`, défaut `172.16.1.129`, DNS `172.16.1.131` après mise en service du DNS.
- VM internes `.131` à `.135` : /27, défaut `.129` ; IP propres à chaque VM.
- ProLiant DMZ : pont non étiqueté vers FW1 e0/1 ; IP à attribuer dans `172.16.3.66-.79` hors `.70-.72`, /26, défaut `.65`. Aucun hyperviseur dans le pool `.83-.126`.
- Hôtes DMZ : `.70`, `.71`, `.72`, `.80`, `.81`, `.82`, masque /26, défaut `172.16.3.65` ; DNS `.71` pour les hôtes autorisés.
- PC01 `.2/27`, GW `.1` ; PC02 `.34/27`, GW `.33` ; PC03 `.98/27`, GW `.97` ; DNS `172.16.1.131`.
- AP1 proposé `172.16.1.66/27`, GW `.65`, mode pont, DHCP désactivé, isolation clients et sécurité Wi-Fi à configurer.

Les adresses clients/AP sont des réservations proposées, à vérifier libres.
Supprimer les anciennes IP secondaires et passerelles après migration ; ne pas
laisser deux routes par défaut concurrentes. Mettre à jour DNS A/PTR, certificats
si nécessaire, ACL locales, supervision et sauvegardes.

## DHCP Wi-Fi

Le serveur est `172.16.1.131`. SW1 Vlan30 relaie vers cette IP. Installer et
autoriser le rôle DHCP dans le domaine réel avant exécution de
[DHCP-WIFI.ps1](DHCP-WIFI.ps1). Ce script crée l'étendue **inactive** :

| Paramètre | Valeur |
| --- | --- |
| Réseau | 172.16.1.64/27 |
| Plage | 172.16.1.67 à 172.16.1.94 |
| Masque | 255.255.255.224 |
| Routeur option 003 | 172.16.1.65 |
| DNS option 006 | 172.16.1.131 |
| Bail | 8 heures |
| Hors plage | GW .65, AP1 .66, réseau .64, broadcast .95 |

Désactiver l'ancienne étendue au basculement, activer la nouvelle après
vérification puis renouveler le bail. Ne pas créer de DHCP sur les pools DMZ,
serveurs ou maintenance. Adapter l'option de domaine DNS seulement au domaine réel.

## DNS et services internes

Windows .131 héberge AD/DNS/DHCP/GLPI. Les clients du domaine utilisent ce DNS.
Pour les noms externes, utiliser Bind `172.16.3.71` si son rôle de résolveur
interne est retenu. Bind doit écouter sur les interfaces utiles, autoriser TCP
et UDP 53, et limiter la récursion à Windows .131 et aux hôtes DMZ inventoriés.
Le rôle « DNS public » de l'ancien schéma ne crée pas de publication Internet :
aucun DNAT DNS n'est prévu. Utiliser un DNS public externe pour le nom HTTPS
publié, pointant vers l'adresse WAN réellement joignable.

Base .132 : moteur/port à confirmer, accès applicatif depuis les seules sources
requises. Zabbix .133 : agents/ports à définir. Squid .134 : port/mode à définir,
pas d'ouverture automatique dans WIFI_IN. Sauvegarde .135 : stockage, hébergement,
rétention et test de restauration à définir. Un snapshot n'est pas une sauvegarde.

## Load balancer et backends

`172.16.3.72/26` termine TLS TCP 443 et répartit vers `.80-.82:80`.
Le modèle [loadbalancer.conf.example](DMZ/loadbalancer.conf.example) contient
les IP cibles ; remplacer les marqueurs de domaine et certificats avant
installation. Vérifier `nginx -t`, puis recharger. Le serveur distinct `.70`
n'est pas publié et n'est pas ajouté au pool applicatif sans besoin validé.

Le playbook des fronts limite Nginx à la source `.72` et au diagnostic local
`127.0.0.1`. Le contrôle `/healthz` utilise un fichier pour que les règles
`allow/deny` s'appliquent aussi à ce chemin. Le trafic SSH d'administration et
les échanges intra-DMZ sont à filtrer sur les pare-feu hôtes/Proxmox.
Nginx n'est pas un pare-feu pour les autres services du serveur.

Le portail d'administration reste réservé au VLAN 40 et aux sources autorisées :
ne pas le placer dans le vhost public du load balancer. Le vhost public ne sert
que les fonctions utilisateur autorisées par le cahier des charges.
