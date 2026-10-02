# Dossier technique du réseau Site B

Référence : [SITE_B_Schema.pdf](SITE_B_Schema.pdf), version 1.1 du 25/09/2026.
Cette cible remplace l'ancien adressage. SW1 assure le routage et les ACL
inter-VLAN ; FW1 contrôle LAN, DMZ et amont. Aucun trunk n'est utilisé.
Les tests sur les équipements restent à réaliser.

## 1 Inventaire du matériel

| Qté | Équipement | Repère ou caractéristiques |
| --- | --- | --- |
| 4 | PC Dell | PC01 à PC03 clients ; PC04 serveur Proxmox interne |
| 1 | Serveur ProLiant | SRV1 - hôte Proxmox de la DMZ |
| 1 | Routeur TP-Link | R1 — modèle à relever |
| 1 | Pare-feu Hillstone | FW1 — modèle à relever |
| 1 | Switch Cisco | SW1 — routage L3 requis ; modèle à vérifier |
| 1 | Switch Zyxel | SW2 - disponible en réserve, absent de la nouvelle topologie |
| 1 | Point d’accès Wi-Fi Netis | AP1 — modèle à relever |
| 4 | Claviers | Connectique à relever |
| 3 | Souris | Connectique à relever |
| 3 | Écrans | Modèles et entrées vidéo à relever |

Trois PC sont utilisés comme postes de travail. PC04 et SRV1 sont des hôtes Proxmox. Les autres équipements ne disposent pas de périphériques attitrés (clavier, souris, écran). Le quatrième clavier reste disponible pour la maintenance.

### Câbles et alimentations

| Qté | Élément | Caractéristiques relevées |
| --- | --- | --- |
| 9 | Câbles Ethernet | Catégorie et longueur à relever |
| 3 | Câbles VGA | Liaisons vidéo |
| 1 | Câble DVI | Liaison vidéo |
| 6 | Alimentations ou cordons secteur | Mention au tableau : 10 A / 240 V ; type à vérifier |
| 1 | Bloc d’alimentation 19,5 V | Entrée 100–240 V, 2,34 A ; sortie 19,5 V, 9,23 A |
| 2 | Blocs d’alimentation 12 V | Entrée 100–240 V, 1 A ; sortie 12 V, 3 A |

Les associations entre blocs d’alimentation et appareils doivent être relevées sur les étiquettes. Les repères PC01 à PC04, SRV1 et AP1 identifient le matériel. Les neuf câbles Ethernet sont utilisés dans le plan actualisé : C02, auparavant en réserve, est affecté à la liaison entre le réseau amont et R1 port 1.


## 2 Réseaux et interfaces

| Zone | Réseau | Passerelle / interfaces | Broadcast |
| --- | --- | --- | --- |
| VLAN 10 Direction | 172.16.1.0/27 | SW1 172.16.1.1 | 172.16.1.31 |
| VLAN 20 Comptabilité | 172.16.1.32/27 | SW1 172.16.1.33 | 172.16.1.63 |
| VLAN 30 Wi-Fi | 172.16.1.64/27 | SW1 172.16.1.65 | 172.16.1.95 |
| VLAN 40 Administration | 172.16.1.96/27 | SW1 172.16.1.97 | 172.16.1.127 |
| VLAN 50 Serveurs | 172.16.1.128/27 | SW1 172.16.1.129 | 172.16.1.159 |
| VLAN 99 Management | 172.16.1.160/27 | SW1 172.16.1.161 | 172.16.1.191 |
| Transit R1-FW1 | 172.16.1.192/30 | R1 port 4 .193 ; FW1 e0/0 .194 | 172.16.1.195 |
| Transit FW1-SW1 | 172.16.1.196/30 | FW1 e0/2 .197 ; SW1 port 24 .198 | 172.16.1.199 |
| Gestion R1 | 172.16.1.224/28 | R1 port 5 172.16.1.226 | 172.16.1.239 |
| Gestion FW1 | 172.16.1.240/28 | FW1 e0/3 172.16.1.241 | 172.16.1.255 |
| DMZ | 172.16.3.64/26 | FW1 e0/1 172.16.3.65 | 172.16.3.127 |

Masques : /27 `255.255.255.224`, /30 `255.255.255.252`, /28
`255.255.255.240`, /26 `255.255.255.192`. Réserve LAN non affectée :
`172.16.1.200/29` et `172.16.1.208/28`. Aucun chevauchement entre les onze réseaux.
Le réseau et la passerelle WAN de R1 port 1 doivent être relevés : le nouveau
schéma ne fixe pas de réseau amont. Chaque /27 offre 30 adresses d'hôtes,
soit 29 après la passerelle, avant les autres réservations.

## 3 Hôtes, réservations et pools

| Hôte / service | IP cible | Passerelle | Statut |
| --- | --- | --- | --- |
| Proxmox Dell interne | 172.16.1.130/27 | 172.16.1.129 | Fixée par schéma |
| Windows AD/DNS/DHCP/GLPI | 172.16.1.131/27 | 172.16.1.129 | Fixée par schéma |
| Base de données | 172.16.1.132/27 | 172.16.1.129 | Fixée par schéma |
| Zabbix | 172.16.1.133/27 | 172.16.1.129 | Fixée par schéma |
| Squid | 172.16.1.134/27 | 172.16.1.129 | Fixée par schéma |
| Sauvegarde Proxmox | 172.16.1.135/27 | 172.16.1.129 | Fixée par schéma |
| Serveur Web DMZ interne | 172.16.3.70/26 | 172.16.3.65 | Aucun DNAT direct |
| DNS Bind DMZ | 172.16.3.71/26 | 172.16.3.65 | Aucun DNAT |
| Load balancer Nginx | 172.16.3.72/26 | 172.16.3.65 | Seul DNAT HTTPS |
| Web1 / Web2 / Web3 | 172.16.3.80, .81, .82 /26 | 172.16.3.65 | Backends |
| Hyperviseur ProLiant DMZ | À réserver dans .66-.79, hors .70-.72 | 172.16.3.65 | Ne pas déployer avant attribution |
| PC01 Direction | 172.16.1.2/27 | 172.16.1.1 | Réservation proposée |
| PC02 Comptabilité | 172.16.1.34/27 | 172.16.1.33 | Réservation proposée |
| PC03 Administration | 172.16.1.98/27 | 172.16.1.97 | Réservation proposée, source ADMIN |
| AP1 Wi-Fi | 172.16.1.66/27 | 172.16.1.65 | Réservation proposée, hors DHCP |
| Poste temporaire VLAN 99 | 172.16.1.162/27 | 172.16.1.161 | Réservation de maintenance |

Les réservations proposées sont des choix de déploiement, pas des IP observées.
Vérifier leur disponibilité avant affectation. Le Dell appelé PC04 dans
l'inventaire historique est « SRV1 » dans le nouveau schéma ; utiliser les
noms explicites « Proxmox Dell interne » et « ProLiant DMZ » pour éviter la
confusion avec l'ancien SRV1 ProLiant. Aucun ajout de matériel n'est présumé
pour le rôle de sauvegarde .135 : son hébergement reste à définir.

| Zone | Plage disponible / DHCP | Exclusions |
| --- | --- | --- |
| VLAN 10 | .3-.30 après réservation PC01 | Réseau .0, GW .1, PC01 .2, broadcast .31 |
| VLAN 20 | .35-.62 après réservation PC02 | Réseau .32, GW .33, PC02 .34, broadcast .63 |
| VLAN 30 | DHCP 172.16.1.67-.94 | Réseau .64, GW .65, AP1 .66, broadcast .95 |
| VLAN 40 | .99-.126 après réservation PC03 | Réseau .96, GW .97, PC03 .98, broadcast .127 |
| VLAN 50 | 172.16.1.136-.158 | GW .129, fixes .130-.135, réseau/broadcast |
| VLAN 99 | .163-.190 après réservation maintenance | GW/SW1 .161, poste .162, réseau/broadcast |
| DMZ | 172.16.3.83-.126 | GW .65, réserve .66-.79, backends .80-.82, réseau/broadcast |

La plage Wi-Fi théorique du schéma est .66-.94 ; la réservation de l'AP réduit
le DHCP à .67-.94 (28 baux). Les autres pools sont des réserves d'allocation,
**pas des étendues DHCP activées**. Toute nouvelle IP fixe doit être retirée
du pool correspondant. Les clients du domaine utilisent le DNS .131 ; ce DNS
redirige les requêtes externes vers Bind 172.16.3.71 si son rôle de résolveur
interne est retenu. Bind n'autorise la récursion que depuis .131 et les hôtes
DMZ autorisés, jamais depuis Internet.

## 4 Câblage et ports

| Câble | Extrémités | Usage |
| --- | --- | --- |
| C01 | R1 port 4 - FW1 e0/0 | Transit 172.16.1.192/30 |
| C02 | Amont - R1 port 1 | WAN à relever |
| C03 | FW1 e0/2 - SW1 port 24 | Transit 172.16.1.196/30, non étiqueté |
| C04 | FW1 e0/1 - ProLiant DMZ | Pont Proxmox DMZ non étiqueté |
| C05 | SW1 port 1 - PC01 | VLAN 10 |
| C06 | SW1 port 5 - PC02 | VLAN 20 |
| C07 | SW1 port 15 - PC03 | VLAN 40 |
| C08 | SW1 port 10 - AP1 LAN | VLAN 30 ; AP pont, DHCP désactivé |
| C09 | SW1 port 22 - Proxmox Dell interne | VLAN 50 ; déplacer depuis port 23 |

Ports SW1 : 1-4 VLAN 10 ; 5-9 VLAN 20 ; 10-14 VLAN 30 ; 15-18 VLAN 40 ;
19-22 VLAN 50 ; 23 VLAN 99 ; 24 routé vers FW1. Les ports inutilisés sont
arrêtés dans l'exemple, à activer après raccordement approuvé.
Le port 23 est réservé à la gestion. Un lien actif dans le VLAN 99 est
nécessaire au maintien de sa SVI selon le modèle. Avec les neuf câbles
inventoriés, déplacer temporairement C07/PC03 vers le port 23, IP .162/27,
ou prévoir un poste et un câble supplémentaires pour un accès permanent.
Ne pas boucler deux ports pour maintenir artificiellement la SVI active.

SW2 reste en réserve. Chaque pont Proxmox transporte uniquement son réseau
local ; pas de trunk. Les échanges entre VM d'un même pont sont filtrés sur
les VM ou Proxmox, puisqu'ils ne passent pas par FW1 ni les ACL inter-VLAN.

## 5 Routage, publication et gestion

- SW1 : défaut via `172.16.1.197`.
- FW1 : routes vers les six /27 VLAN via `172.16.1.198` ; défaut via `172.16.1.193`.
- R1 : les six /27 VLAN, `172.16.1.196/30` et `172.16.3.64/26` via `172.16.1.194` ; défaut via le WAN relevé.
- Pas de route globale `172.16.1.0/24` vers SW1 : le bloc inclut les transits et la maintenance.
- Pas de routes annoncées vers les réseaux de gestion locale R1/FW1.

R1 réalise le NAT de sortie des réseaux autorisés. FW1 ne traduit pas LAN-DMZ.
Si le modèle R1 ne sait pas traduire les réseaux routés, documenter une variante
SNAT sur FW1 e0/0 avant déploiement ; elle n'est pas la cible de référence.
Publication : R1 TCP 443 vers FW1 `172.16.1.194:443`, puis FW1 vers
`172.16.3.72:443`. Aucun DNAT TCP 80, DNS, SSH, hyperviseur ou backend.
Le load balancer termine TLS et joint Web1-Web3 sur TCP 80 interne, correspondant
au playbook disponible. .70 est un service Web distinct non publié ; son
intégration éventuelle au load balancer nécessite un choix applicatif explicite.

Gestion locale : PC03 débranché du LAN et raccordé directement à R1 port 5
avec .227/28 sans passerelle, ou à FW1 e0/3 avec .242/28 sans passerelle.
Ces deux segments restent distincts. Après maintenance, restaurer PC03
.98/27, GW .97, DNS .131 et C07 port 15.

SW1 : la SVI VLAN 99 porte `172.16.1.161/27`. Les lignes VTY ne portent
aucune IP. Une connexion distante peut atteindre d'autres IP de SW1 si
elles sont routables ; l'ACL VTY fournie restreint les **sources**, pas la
seule IP destination .161. SSH nécessite aussi identité locale/AAA, domaine
et clés RSA, à préparer en console avant activation.

## 6 Politique de filtrage

Les ACL IOS sont sans état. Prévoir les flux inverses UDP/ICMP et les réponses
TCP (ACK/RST avec `established`, sans équivalence à un pare-feu à états).
Placer les exceptions avant les refus de réseaux privés. FW1 assure le suivi
de session et autorise les retours des sessions permises.

| Source | Destination | Flux cible |
| --- | --- | --- |
| VLAN 30 | Windows .131 | DNS TCP/UDP 53 ; DHCP UDP 68 vers 67 |
| Relais SW1 VLAN 30 .65 | Windows .131 | UDP 67 vers 67, réponses inverses |
| VLAN 10/20 et PC03 | Windows .131 | DNS, AD, GLPI HTTPS |
| Clients domaine | Windows .131 | TCP 88/135/389/445/464/3268/49152-65535 ; UDP 88/123/389/464, ICMP |
| PC03 .98 | Équipements/hyperviseurs/VM inventoriés | SSH 22, HTTPS 443, Proxmox 8006 ; Windows 3389/5986/9389 selon service |
| Windows .131 | Base .132 | Port choisi du moteur, à confirmer |
| Zabbix .133 | Agents inventoriés | TCP 10050 ; retours/collectes TCP 10051 selon mode |
| Clients autorisés | Squid .134 | Port du proxy retenu ; Wi-Fi exclu par ACL fournie |
| VLAN 10/20 et PC03 | Load balancer .72 | HTTPS 443 |
| Windows .131 | Bind 172.16.3.71 | DNS TCP/UDP 53 |
| Load balancer .72 | Web1 .80, Web2 .81, Web3 .82 | HTTP TCP 80, local DMZ |
| DMZ | LAN | Refuser nouvelles sessions |
| VLAN 30 | Autres réseaux privés | Refuser hors DNS/DHCP ci-dessus |
| LAN/DMZ autorisés | Internet | HTTPS ; DNS/NTP vers destinations approuvées ; HTTP seulement si besoin de dépôts validé |

L'exemple SW1 applique le filtre VLAN 30 et l'ACL VTY. Les ACL des autres
VLAN doivent être réalisées selon cette matrice et les services réellement
retenus avant une recette de sécurité complète. Les échanges intra-VLAN
restent protégés par les pare-feu des hôtes. Les règles FW1 sont détaillées
dans [R1_FW1.md](../configuration/R1_FW1.md).

## 7 Migration, recette et retour arrière

1. Sauvegarder équipements et VM ; relever modèles, ports, WAN, accès console et IP manquantes.
2. Préparer les adresses et masques des hôtes, DNS, DHCP et certificats ; désactiver l'ancienne étendue DHCP avant d'activer la nouvelle.
3. Recâbler FW1 (e0/0 amont, e0/1 DMZ, e0/2 LAN, e0/3 gestion) et C09 vers SW1 port 22.
4. Remplacer les anciennes IP et routes ; ne pas simplement ajouter les nouvelles. Vérifier chaque voisin puis les routes de retour.
5. Configurer SVI, relais DHCP, DNS et services ; appliquer les ACL et règles FW1 avec console disponible.
6. Tester le LAN et les backends, puis le load balancer TLS ; activer le DNAT 443 en dernier.
7. Sauvegarder définitivement uniquement après recette. En cas d'échec, restaurer le jeu cohérent d'IP, routes, ACL, DHCP et câblage sauvegardé.

| Test | Résultat attendu |
| --- | --- |
| SW1 vers .197 ; FW1 vers .193 | Transits joignables ; masques /30 |
| DHCP Wi-Fi | .67-.94, /27, GW .65, DNS .131 ; jamais .65/.66/.95 |
| DNS et domaine VLAN 10/20 | Résolution, adhésion, session et GPO fonctionnelles |
| Wi-Fi vers LAN, DMZ et gestion | Refus hors DNS/DHCP ; retours DHCP/DNS fonctionnels |
| PC03 vers SW1 SSH ; PC01 vers SW1 SSH | PC03 autorisé ; PC01 refusé par ACL VTY |
| Port 23 / VLAN 99 | SVI .161 opérationnelle si lien actif ; test depuis .162 |
| Gestion R1 et FW1 | Accès local séparé puis restauration PC03 sur VLAN 40 |
| HTTPS externe | Seul .72 atteint via R1/FW1 ; certificat valide |
| Backends | HTTP depuis .72 autorisé ; accès direct depuis clients refusé au niveau Nginx |
| DMZ vers LAN | Nouvelles sessions refusées ; retours des sessions LAN permises acceptés |
| Base, Zabbix, Squid, sauvegarde | Flux autorisés et refusés vérifiés selon services retenus |
| Internet, routes retour, NAT | LAN et DMZ autorisés sortent via R1 ; aucun NAT LAN-DMZ |
| Persistance / restauration | Configurations sauvegardées ; tests essentiels répétés après redémarrage |

Conserver date, source, destination, commande, résultat observé et compteurs.
Aucun test matériel n'est réputé réussi par la seule validation des fichiers.

## 8 Paramètres restant à relever

Modèles/versions/interfaces, WAN R1, prise en charge NAT des réseaux routés,
IP hyperviseur DMZ, hébergement sauvegarde .135, domaine AD/DNS, certificats,
résolveurs et NTP, ports base/Squid/Zabbix, accès SSH/AAA et maintien de la SVI 99.
IPv6 doit recevoir un plan et un filtrage distincts s'il est activé.
