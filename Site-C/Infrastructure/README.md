# Site C — plan d’adressage

Architecture : **Internet → R1 → Hillstone**, puis trois branches : **switch L3 / proxy / caméras**. Le Hillstone possède quatre interfaces ; aucun R2.

[Schéma et ACL](docs/Dossier_reseau.md) · [Configuration du switch](configuration/Switch-L3.txt) · [Configuration Hillstone](configuration/Pare-feu-Hillstone.md). Les PDF sont des documents sources historiques ; ce plan fait référence pour la maquette actuelle.

**LAN : 172.16.2.0/24**, découpé en 8 /27 : 7 attribués et 1 bloc IP libre. **DMZ : 172.16.3.128/26**, divisée en 2 /27. Tous les sous-réseaux utilisent le masque **255.255.255.224** (30 hôtes, passerelle comprise).

| VLAN / zone | Usage | Sous-réseau | Passerelle | Hôtes utilisables | Broadcast |
|---|---|---|---|---|---|
| 10 | Service 1 | 172.16.2.0/27 | 172.16.2.1 (SW) | .1 à .30 | .31 |
| 20 | Service 2 | 172.16.2.32/27 | 172.16.2.33 (SW) | .33 à .62 | .63 |
| 30 | Serveurs / 3 Proxmox | 172.16.2.64/27 | 172.16.2.65 (SW) | .65 à .94 | .95 |
| 40 | Wi-Fi employés | 172.16.2.96/27 | 172.16.2.97 (SW) | .97 à .126 | .127 |
| 50 | VoIP | 172.16.2.128/27 | 172.16.2.129 (SW) | .129 à .158 | .159 |
| 60 | Wi-Fi invités | 172.16.2.160/27 | 172.16.2.161 (SW) | .161 à .190 | .191 |
| Non attribué | Réserve IP sans VLAN | 172.16.2.192/27 | Aucune | .193 à .222 | .223 |
| 99 | Management | 172.16.2.224/27 | 172.16.2.225 (SW) | .225 à .254 | .255 |
| Réseau caméras | Caméras, interface dédiée | 172.16.3.128/27 | 172.16.3.129 (Hillstone) | .129 à .158 | .159 |
| Réseau proxy | Reverse proxy DMZ | 172.16.3.160/27 | 172.16.3.161 (Hillstone) | .161 à .190 | .191 |

Les caméras et le proxy utilisent deux interfaces physiques séparées du Hillstone, sans tags VLAN. Aucun VLAN 70/71 ni SVI DMZ sur le switch. Le proxy rejoint le pare-feu via la carte 2 de Proxmox 2.

## Comment le découpage a été fait

- **LAN /24 vers /27** : on emprunte 3 bits à la partie hôte. Cela donne `2³ = 8` sous-réseaux égaux.
- **DMZ /26 vers /27** : on emprunte 1 bit. Cela donne `2¹ = 2` sous-réseaux égaux.
- Un `/27` contient `2⁵ = 32` adresses, soit **30 adresses utilisables** après retrait de l'adresse réseau et du broadcast. Son masque est `255.255.255.224`.
- Le pas est de **32** : le LAN commence à `.0`, `.32`, `.64`, `.96`, `.128`, `.160`, `.192` et `.224`. La DMZ commence à `172.16.3.128` et `172.16.3.160`.
- Exemple VLAN 30 : réseau `172.16.2.64/27`, hôtes `.65` à `.94`, broadcast `.95`. La première adresse utilisable `.65` sert de passerelle ; il reste 29 adresses pour les équipements.

## Réserve IP

Le bloc **172.16.2.192/27** reste libre pour une évolution : **172.16.2.193 à 172.16.2.222**, soit 30 adresses utilisables. `.192` est l'adresse réseau et `.223` le broadcast. Aucun VLAN, aucune SVI, aucune passerelle et aucun pool DHCP ne lui sont affectés. Les autres VLAN gardent leurs adresses actuelles.

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

| Liaison | Réseau / masque | Côté 1 | Côté 2 |
|---|---|---|---|
| R1 ↔ Hillstone WAN | 192.168.0.0/30 — 255.255.255.252 | R1 : 192.168.0.1 | Hillstone : 192.168.0.2 |
| Switch ↔ Hillstone LAN | 192.168.0.4/30 — 255.255.255.252 | Switch Gi1/0/24 : 192.168.0.5 | Hillstone : 192.168.0.6 |

Le nouveau bloc `192.168.0.4/30` est proposé : vérifier qu'il est libre. L'ancienne IP `.2` du switch est transférée au Hillstone WAN ; ne pas activer les deux équipements avec cette IP sur le même lien. L'ancienne adresse `172.16.2.70` est libre dans le VLAN 30, sans nouvelle affectation. La réserve `172.16.2.192/27` reste entière.

Routes : switch → défaut `.6` ; Hillstone → LAN `172.16.2.0/24` via `.5`, défaut via R1 `.1` ; R1 → réseaux internes via `.2`.

[Câblage et fonctionnement](docs/Dossier_reseau.md) · [Audit](docs/Audit_Site_C.md)
