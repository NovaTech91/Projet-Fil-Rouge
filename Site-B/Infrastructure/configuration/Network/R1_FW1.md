# Paramètres R1 et FW1 - schéma version 1.1

Ces tableaux sont une configuration cible à saisir dans les interfaces TP-Link
et Hillstone StoneOS. Les modèles/versions n'étant pas connus, aucune syntaxe
CLI constructeur non vérifiée n'est fournie. Sauvegarder les exports avant
modification ; conserver un accès console/local.

## Interfaces

| Équipement | Port | Zone / réseau | IP / masque |
| --- | --- | --- | --- |
| R1 | 1 | WAN | IP, masque, mode et passerelle à relever |
| R1 | 4 | Transit FW1 | 172.16.1.193 / 255.255.255.252 |
| R1 | 5 | Gestion locale R1 | 172.16.1.226 / 255.255.255.240 |
| FW1 | e0/0 | AMONT / R1 | 172.16.1.194 / 255.255.255.252 |
| FW1 | e0/1 | DMZ | 172.16.3.65 / 255.255.255.192 |
| FW1 | e0/2 | LAN / SW1 port 24 | 172.16.1.197 / 255.255.255.252 |
| FW1 | e0/3 | GESTION locale FW1 | 172.16.1.241 / 255.255.255.240 |

e0/2 est un lien L3 non étiqueté, pas une interface trunk. Les réseaux de
maintenance R1 172.16.1.224/28 et FW1 172.16.1.240/28 sont physiquement séparés.
Ne pas ponter les ports de gestion au transit ou au LAN. Pas de DHCP sur les
transits ni sur la maintenance. Conserver les IP des autres interfaces SW1
dans [SW1.conf](SW1.conf).

## Routes statiques

| Destination | Masque | FW1 : prochain saut | R1 : prochain saut |
| --- | --- | --- | --- |
| 172.16.1.0 | 255.255.255.224 | 172.16.1.198 | 172.16.1.194 |
| 172.16.1.32 | 255.255.255.224 | 172.16.1.198 | 172.16.1.194 |
| 172.16.1.64 | 255.255.255.224 | 172.16.1.198 | 172.16.1.194 |
| 172.16.1.96 | 255.255.255.224 | 172.16.1.198 | 172.16.1.194 |
| 172.16.1.128 | 255.255.255.224 | 172.16.1.198 | 172.16.1.194 |
| 172.16.1.160 | 255.255.255.224 | 172.16.1.198 | 172.16.1.194 |
| 172.16.1.196 | 255.255.255.252 | Direct e0/2 | 172.16.1.194 |
| 172.16.3.64 | 255.255.255.192 | Direct e0/1 | 172.16.1.194 |
| 0.0.0.0 | 0.0.0.0 | 172.16.1.193 | Passerelle WAN relevée |

Les routes directement connectées ne sont pas à recréer en statique.
SW1 utilise un défaut via 172.16.1.197. Aucune route résumée 172.16.1.0/24
vers SW1 et aucune route annoncée vers les deux réseaux de maintenance.

## Objets FW1

- LAN_VLANS : les six /27 ci-dessus (ne pas utiliser l'enveloppe /24).
- ADMIN : PC03 `172.16.1.98` ; maintenance SW1 `172.16.1.162` uniquement si nécessaire.
- WINDOWS : `172.16.1.131` ; DNS_DMZ : `172.16.3.71`.
- LB : `172.16.3.72` ; BACKENDS : `172.16.3.80`, `.81`, `.82`.
- SERVEURS_DMZ : `.70`, `.71`, `.72`, `.80`, `.81`, `.82`, puis IP hyperviseur attribuée.
- RESEAUX_PRIVES : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- DNS_EXTERNES et NTP_EXTERNES : listes d'IP approuvées à renseigner, pas `any`.

## Politique FW1 ordonnée

| Ordre | Source | Destination | Service / action |
| --- | --- | --- | --- |
| 10 | Sessions permises | Retour | Suivi de session, erreurs ICMP associées |
| 20 | AMONT, publication R1 | LB en DMZ | Autoriser TCP 443 correspondant au DNAT |
| 30 | LAN, PC03 .98 | Hôtes DMZ inventoriés | SSH 22, HTTPS 443, hyperviseur 8006 et ICMP selon besoin ; IP hyperviseur à compléter |
| 40 | LAN, VLAN 10/20 et PC03 | LB .72 | Autoriser TCP 443 |
| 50 | LAN, Windows .131 | DNS_DMZ .71 | Autoriser TCP/UDP 53 |
| 60 | DMZ, tous | LAN, tous | Refuser toute nouvelle session et journaliser |
| 70 | LAN, PC03 .98 | R1 .193 | Administration HTTPS/SSH disponible et ICMP |
| 80 | LAN/DMZ, autres | AMONT, réseaux privés | Refuser ; exceptions d'administration placées avant |
| 90 | LAN, hôtes autorisés | AMONT, Internet hors réseaux privés | Autoriser HTTPS TCP 443 |
| 100 | DMZ, serveurs inventoriés | AMONT, Internet hors réseaux privés | Autoriser HTTPS TCP 443 pour mises à jour |
| 110 | DMZ, Bind .71 | AMONT, DNS_EXTERNES | Autoriser TCP/UDP 53 |
| 120 | Serveurs LAN/DMZ autorisés | AMONT, NTP_EXTERNES | Autoriser UDP 123 |
| 999 | Toute source | Toute destination | Refuser et journaliser |

Si un dépôt de paquets utilise HTTP, migrer sa source vers HTTPS ou ajouter
une exception TCP 80 limitée au dépôt nécessaire après validation ; ne pas
ouvrir globalement HTTP pour rendre une installation fonctionnelle.
La règle WAN et le DNAT doivent cibler le bon objet selon l'ordre NAT/filtrage
de la version StoneOS : confirmer l'adresse avant/après traduction avec les
journaux et un test externe. Les flux entre backends et LB restent locaux
à la DMZ : contrôle Nginx et pare-feu hôtes/Proxmox requis.

## NAT et publication

| Équipement | Entrée | Traduction |
| --- | --- | --- |
| R1 | LAN routés et DMZ autorisés vers WAN port 1 | SNAT/PAT sur l'IP WAN |
| R1 | WAN TCP 443 | DNAT vers 172.16.1.194 TCP 443 |
| FW1 | AMONT e0/0 TCP 443 pour la publication | DNAT vers 172.16.3.72 TCP 443 |

Ne pas créer de DNAT vers les backends, le serveur .70, Bind .71, les
hyperviseurs ou un service d'administration. Aucune publication TCP 80.
Ne pas activer de SNAT LAN-DMZ : le load balancer et les hôtes doivent conserver
la visibilité des sources. Vérifier les routes retour avant d'envisager un NAT
supplémentaire. Une IP WAN privée nécessite une publication sur l'amont pour
être joignable depuis Internet ; la simple configuration locale ne la garantit pas.

## Administration locale et R1

- R1 port 5 : poste .227/28 sans passerelle ; accès .226 limité à ce poste.
- FW1 e0/3 : poste .242/28 sans passerelle ; accès .241 limité à ce poste.
- Administration FW1 sur e0/2 .197 uniquement depuis PC03 .98 si activée.
- Désactiver l'administration WAN, UPnP et les ouvertures automatiques sur R1.
- R1 accepte les retours des sessions autorisées et l'entrée TCP 443 publiée ; refuser les autres nouvelles connexions WAN.
- Les règles d'administration locale sont distinctes des règles de transit.

Vérifier transit, routes retour, compteurs de règles, DNAT externe et refus DMZ
vers LAN ; exporter les configurations seulement après recette.
