# Site C — plan d’adressage

Architecture : **Internet → R1 → Hillstone**, puis trois branches : **switch L3 / proxy / caméras**. Le Hillstone possède quatre interfaces ; aucun R2.

[Schéma et ACL](docs/Dossier_reseau.md) · [Configuration du switch](configuration/Switch-L3.txt) · [Configuration Hillstone](configuration/Pare-feu-Hillstone.md). Les PDF sont des documents sources historiques ; ce plan fait référence pour la maquette actuelle.

**LAN : 172.16.2.0/24**, découpé initialement en 8 /27 : 7 pour les VLAN, le dernier partagé entre le transit /30 et la réserve. **DMZ : 172.16.3.128/26**, divisée en 2 /27. Les VLAN et réseaux DMZ utilisent **255.255.255.224 (/27)**. Le transit switch–Hillstone utilise **255.255.255.252 (/30)**, soit deux adresses utilisables.

| VLAN / zone | Usage | Sous-réseau | Passerelle | Hôtes utilisables | Broadcast |
|---|---|---|---|---|---|
| 10 | Service 1 | 172.16.2.0/27 | 172.16.2.1 (SW) | .1 à .30 | .31 |
| 20 | Service 2 | 172.16.2.32/27 | 172.16.2.33 (SW) | .33 à .62 | .63 |
| 30 | Serveurs / 3 Proxmox | 172.16.2.64/27 | 172.16.2.65 (SW) | .65 à .94 | .95 |
| 40 | Wi-Fi employés | 172.16.2.96/27 | 172.16.2.97 (SW) | .97 à .126 | .127 |
| 50 | VoIP | 172.16.2.128/27 | 172.16.2.129 (SW) | .129 à .158 | .159 |
| 60 | Wi-Fi invités | 172.16.2.160/27 | 172.16.2.161 (SW) | .161 à .190 | .191 |
| Transit routé | Switch ↔ Hillstone | 172.16.2.192/30 | Hillstone .194 | .193 à .194 | .195 |
| Non attribué | Réserve à découper | 172.16.2.196–223 | Aucune | Selon découpage futur | Selon découpage futur |
| 99 | Management | 172.16.2.224/27 | 172.16.2.225 (SW) | .225 à .254 | .255 |
| Réseau caméras | Caméras, interface dédiée | 172.16.3.128/27 | 172.16.3.129 (Hillstone) | .129 à .158 | .159 |
| Réseau proxy | Reverse proxy DMZ | 172.16.3.160/27 | 172.16.3.161 (Hillstone) | .161 à .190 | .191 |

Les caméras et le proxy sont raccordés à deux interfaces physiques séparées du Hillstone, sans tags VLAN ni SVI DMZ sur le switch. Le proxy rejoint le pare-feu via la carte 2 de Proxmox 2.

## Comment le découpage a été fait

- **LAN /24 vers /27** : on emprunte 3 bits à la partie hôte. Cela donne `2³ = 8` sous-réseaux égaux.
- **DMZ /26 vers /27** : on emprunte 1 bit. Cela donne `2¹ = 2` sous-réseaux égaux.
- Un `/27` contient `2⁵ = 32` adresses, soit **30 adresses utilisables** après retrait de l'adresse réseau et du broadcast. Son masque est `255.255.255.224`.
- Le pas est de **32** : le LAN commence à `.0`, `.32`, `.64`, `.96`, `.128`, `.160`, `.192` et `.224`. La DMZ commence à `172.16.3.128` et `172.16.3.160`.
- Exemple VLAN 30 : réseau `172.16.2.64/27`, hôtes `.65` à `.94`, broadcast `.95`. La première adresse utilisable `.65` sert de passerelle ; il reste 29 adresses pour les équipements.

## Réserve IP

Dans le bloc **172.16.2.192/27 réservé aux liaisons et à l'extension**, les quatre premières adresses forment le transit **172.16.2.192/30** : réseau `.192`, switch `.193`, pare-feu `.194`, broadcast `.195`. Le lien est routé, sans création de VLAN.

Il reste **172.16.2.196 à 172.16.2.223**, soit **28 adresses non attribuées**. Elles peuvent être découpées en `172.16.2.196/30`, `172.16.2.200/29` et `172.16.2.208/28`. Ce ne sont pas 28 adresses hôtes garanties : les adresses réseau/broadcast dépendront du découpage retenu. Aucun pool DHCP ne doit utiliser ces blocs. Les sous-réseaux des VLAN décrits ici sont attribués séparément.

## Adresses fixes prévues

| Équipement / service | Adresse /27 | Passerelle |
|---|---|---|
| AD / DNS / DHCP | 172.16.2.66 | 172.16.2.65 |
| Zabbix | 172.16.2.67 | 172.16.2.65 |
| Proxmox 2 — gestion | 172.16.2.68 | 172.16.2.65 |
| Web 1 sur Proxmox 1 | 172.16.2.69 | 172.16.2.65 |
| Web 2 sur Proxmox 1 | 172.16.2.71 | 172.16.2.65 |
| Proxmox 1 — gestion | 172.16.2.72 | 172.16.2.65 |
| Proxmox 3 — gestion | 172.16.2.73 | 172.16.2.65 |
| IPBX (prévu) | 172.16.2.130 | 172.16.2.129 |
| Caméras | 172.16.3.130 à .158 | 172.16.3.129 |
| Hillstone — port caméras | 172.16.3.129 | — |
| Hillstone — port proxy | 172.16.3.161 | — |
| Reverse proxy sur Proxmox 2 | 172.16.3.162 | 172.16.3.161 |

Exclure ces adresses fixes des baux DHCP. Les adresses .72/.73 des nouveaux nœuds sont des affectations proposées à vérifier avant déploiement.

## Transits entre équipements

**Liaison switch–pare-feu : `172.16.2.192/30`**, prise dans la réserve du réseau LAN fourni. Les deux configurations et le schéma utilisent les adresses ci-dessous.

- **Switch Gi1/0/24 : `172.16.2.193`**.
- **Hillstone, interface LAN : `172.16.2.194`**. C'est le prochain saut par défaut du switch.
- **Masque : `255.255.255.252` (/30)**. Il suffit pour les deux extrémités d'un câble ; `.192` désigne le réseau et `.195` le broadcast.
- **Liaison R1–Hillstone : `192.168.0.0/30`** : R1 `.1`, Hillstone WAN `.2`. Ce lien dédié rejoint l'accès Internet.

Le plan attribue quatre adresses au transit ; `.196–.223` restent non attribuées.

| Liaison | Réseau / masque | Côté 1 | Côté 2 |
|---|---|---|---|
| R1 ↔ Hillstone WAN | 192.168.0.0/30 — 255.255.255.252 | R1 : 192.168.0.1 | Hillstone : 192.168.0.2 |
| Switch ↔ Hillstone LAN | 172.16.2.192/30 — 255.255.255.252 | Switch Gi1/0/24 : 172.16.2.193 | Hillstone : 172.16.2.194 |

Le transit est prélevé sur le bloc réservé aux liaisons : il ne chevauche aucun des sept VLAN. Avant le déploiement, vérifier que ces plages sont libres dans l'environnement de la maquette. Le lien R1–Hillstone utilise séparément `192.168.0.0/30`.

Routes : switch → défaut `172.16.2.194` ; Hillstone → LAN `172.16.2.0/24` via `172.16.2.193`, défaut via R1 `192.168.0.1` ; R1 → LAN/DMZ via `192.168.0.2`. Le transit est inclus dans la route LAN /24 de R1.

[Câblage et fonctionnement](docs/Dossier_reseau.md) · [Audit](docs/Audit_Site_C.md)
