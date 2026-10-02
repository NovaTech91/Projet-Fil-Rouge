# Hillstone — quatre interfaces

Configuration à saisir dans **StoneOS WebUI**. Les quatre noms de ports physiques et les menus sont à identifier sur le modèle/version utilisé ; ce document n'est pas un script CLI. Configurer depuis la console et sauvegarder l'existant.

## Interfaces L3 et routes

Créer quatre zones L3 distinctes, dans le même VRouter. Chaque port est dédié et non tagué ; aucun trunk ni bridge entre zones.

| Port à identifier | Zone proposée | IP / masque | Raccordement |
|---|---|---|---|
| 1 | WAN_R1 | 192.168.0.2/30 — 255.255.255.252 | R1 : 192.168.0.1 |
| 2 | LAN_SITE_C | 192.168.0.6/30 — 255.255.255.252 | Switch Gi1/0/24 : 192.168.0.5 |
| 3 | DMZ_PROXY | 172.16.3.161/27 — 255.255.255.224 | Carte 2 Proxmox 2 → VM proxy .162 |
| 4 | CAMERAS | 172.16.3.129/27 — 255.255.255.224 | Caméra ou switch PoE dédié aux caméras |

Vérifier que `192.168.0.4/30` est libre. Ne pas activer DHCP sur ces ports. Les caméras ont des IP fixes `.130–.158`, passerelle `.129`.

| Route sur Hillstone | Prochain saut | Sortie |
|---|---|---|
| 172.16.2.0/24 | 192.168.0.5 | LAN_SITE_C |
| 0.0.0.0/0 | 192.168.0.1 | WAN_R1 |

Les deux réseaux DMZ sont directement connectés. Le switch utilise la route par défaut via `192.168.0.6`. **Aucun NAT sur le Hillstone dans cette base** : ni entre zones internes ni vers R1. Le NAT Internet est conservé/préparé sur R1, avec les routes de retour indiquées plus bas.

## Objets à créer

| Objet | Valeur |
|---|---|
| LAN | 172.16.2.0/24 |
| CLIENTS_WEB | Groupe : 172.16.2.0/27, 172.16.2.32/27, 172.16.2.96/27, 172.16.2.160/27, 172.16.2.224/27 |
| ADMIN | 172.16.2.224/27 |
| PROXY | 172.16.3.162/32 |
| WEB_SERVEURS | Groupe : 172.16.2.69/32 et 172.16.2.71/32 |
| CAMERAS_NET | 172.16.3.128/27 |
| DNS | 172.16.2.66/32 |
| ZABBIX | 172.16.2.67/32 |
| PRIVES | Groupe : 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 |

Services : WEB = TCP destination 80 + 443 ; DNS = UDP/TCP destination 53 ; NTP = UDP destination 123 ; SSH = TCP destination 22 ; ZABBIX_ACTIF = TCP destination 10051 ; PING = ICMP echo-request. Pour TCP/UDP, les ports source restent quelconques.

## Politiques, dans cet ordre

| N° | Zones source → destination | Source | Destination | Service | Action |
|---|---|---|---|---|---|
| 1 | LAN_SITE_C → DMZ_PROXY | CLIENTS_WEB | PROXY | WEB | Autoriser |
| 2 | LAN_SITE_C → DMZ_PROXY | ADMIN | PROXY | SSH + PING | Autoriser |
| 3 | DMZ_PROXY → LAN_SITE_C | PROXY | WEB_SERVEURS | WEB | Autoriser |
| 4 | LAN_SITE_C → CAMERAS | ADMIN | CAMERAS_NET | WEB + SSH + PING | Autoriser |
| 5 | CAMERAS → LAN_SITE_C | CAMERAS_NET | DNS | DNS | Autoriser |
| 6 | CAMERAS → LAN_SITE_C | CAMERAS_NET | ZABBIX | ZABBIX_ACTIF | Autoriser |
| 7 | LAN_SITE_C → WAN_R1 | LAN | PRIVES | Tous | Refuser |
| 8 | LAN_SITE_C → WAN_R1 | DNS | Toutes | DNS | Autoriser |
| 9 | LAN_SITE_C → WAN_R1 | LAN | Toutes | WEB + NTP | Autoriser |
| 10 | Toutes → toutes | Toutes | Toutes | Tous | Refuser + journaliser |

Supprimer les anciennes permissions trop larges et les éventuelles règles NAT automatiques. Activer la journalisation des connexions pendant la recette. Le pare-feu suit les sessions : les réponses aux connexions permises sont acceptées automatiquement, sans règles Cisco `established`.

Les caméras ne communiquent ni avec le proxy ni avec Internet. Le port Zabbix actif est une hypothèse conservée, à vérifier avec les caméras réelles ; SNMP/RTSP et autres besoins ne sont pas ouverts. Le proxy utilise les IP des Web : son DNS, ses mises à jour et la publication publique restent à préparer. Les nouvelles connexions Internet → réseaux internes sont refusées.

## Administration du Hillstone

Changer les identifiants par défaut. Activer HTTPS et SSH seulement sur le port LAN `192.168.0.6` ; désactiver HTTP/Telnet et l'administration sur WAN, proxy et caméras. Dans **System → Device Management → Trust Host** (selon version), autoriser uniquement `172.16.2.224/27` en HTTPS/SSH et retirer toute autorisation globale. Les règles de transit ne remplacent pas cette restriction de gestion locale.

## R1 : accès Internet et routes de retour

R1 est directement relié au port WAN du Hillstone ; son adresse côté interne reste `192.168.0.1/30`. La sortie opérateur n'est pas connue, donc sa configuration complète/NAT ne peut pas être fournie ici.

Routes Cisco à intégrer à la configuration existante de R1, en remplaçant les anciennes routes incompatibles :

```cisco
ip route 172.16.2.0 255.255.255.0 192.168.0.2
ip route 172.16.3.128 255.255.255.192 192.168.0.2
ip route 192.168.0.4 255.255.255.252 192.168.0.2
```

Prévoir le NAT/PAT de `172.16.2.0/24` sur la sortie Internet de R1, sa route par défaut opérateur et ses filtres adaptés. L'accès Internet ne fonctionnera qu'après cette étape ; le fonctionnement interne ne dépend pas du NAT. Ne pas ajouter en parallèle un SNAT Hillstone sans revoir ce choix.

Sources : [zones StoneOS](https://www.hillstonenet.com/support/X-series/5.0/en/config_net_zone_intro.html), [politiques](https://www.hillstonenet.com/support/4.5/en/SG/config_policy_intro.html), [Trust Host](https://www.hillstonenet.com/support/X-series/5.0/en/config_sys_devmanage_host.html).
