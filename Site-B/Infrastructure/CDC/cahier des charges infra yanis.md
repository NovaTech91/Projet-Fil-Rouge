# Cahier des charges de l'infrastructure - Site B

## 1. Identification du document

| Champ | Valeur |
| --- | --- |
| Projet | Projet Fil Rouge - infrastructure multisite |
| Nature | Cahier des charges technique du lab |
| Site concerné | Site B |
| Périmètre | Réseau, sécurité, systèmes, virtualisation, services, VPN intersite, disponibilité, supervision, sauvegarde et exploitation |
| Version | 0.1 |
| Date | 02/10/2026 |
| Statut | Document de travail du lab |
| Référence technique locale | Schéma réseau Site B, version 1.1 du 25/09/2026 |

### 1.1 Objet du document

Le présent cahier des charges définit les besoins, contraintes, exigences techniques et critères de recette de l'infrastructure du **Site B**. Il couvre uniquement l'infrastructure nécessaire au fonctionnement du site et à son intégration dans le laboratoire multisite.

Il ne remplace pas le cahier des charges de l'application Web. Les fonctions métier, les écrans, les parcours utilisateurs et le développement des portails sont hors du présent document. Seules les dépendances d'infrastructure de ces applications sont traitées : hébergement, réseau, sécurité, répartition de charge, haute disponibilité, certificats, supervision, sauvegarde et accès d'administration.

### 1.2 Règles de priorité documentaire

En cas de divergence entre les sources :

1. le schéma réseau Site B version 1.1 et le dossier réseau Site B font autorité pour l'adressage et la topologie locale ;
2. les fichiers de configuration du Site B constituent des exemples de mise en œuvre à adapter et à tester, et non la preuve d'un déploiement réussi ;
3. les documents des Sites A et C servent uniquement à comprendre le besoin client commun et la cible multisite ; leurs adresses, matériels et paramètres ne doivent pas être appliqués au Site B ;
4. l'ancien fichier `Schema SRV.png` est une archive historique non applicable ; ses réseaux en `192.168.50.0/24` et `10.0.20.0/24` ne doivent pas être réutilisés.

### 1.3 Périmètre multisite acté

Le périmètre est acté : le lab comprend **trois sites géographiques A, B et C**, interconnectés par VPN IPsec. La mention de quatre agences présente dans un ancien cahier des charges est obsolète et ne doit pas être utilisée pour concevoir l'infrastructure.

## 2. Contexte et expression du besoin

Le lab représente une infrastructure d'entreprise segmentée et sécurisée sur trois sites. Chaque site possède son propre réseau local, ses équipements et ses services. Les trois sites doivent communiquer par des tunnels VPN IPsec sans exposer leurs réseaux privés sur Internet.

L'infrastructure doit fournir :

- une séparation des usages par VLAN ;
- des services d'identité, de résolution de noms, d'adressage, de ticketing, de supervision, de proxy et de sauvegarde ;
- une zone DMZ isolée pour les services Web ;
- l'hébergement de deux services Web internes, dont le détail fonctionnel relève du cahier des charges Web ;
- une architecture Web tolérante à la panne, avec des serveurs répartis sur les trois sites ;
- une administration séparée des réseaux utilisateurs ;
- une supervision consolidée des sites, des serveurs, des hyperviseurs, des VPN et des sauvegardes ;
- une traçabilité des connexions et des actions d'administration ;
- un accès distant sécurisé sans publication directe de RDP ou SSH sur Internet.

Le Site B doit pouvoir fonctionner localement pour ses services essentiels et s'intégrer à la cible multisite sans utiliser les plans d'adressage des Sites A et C dans sa configuration locale.

## 3. Objectifs

### 3.1 Objectifs principaux

- Déployer le plan d'adressage validé du Site B sans chevauchement.
- Segmenter le LAN en six VLAN et séparer le LAN, la DMZ, l'amont et les réseaux de maintenance.
- Appliquer une politique de filtrage fondée sur le refus par défaut et le moindre privilège.
- Héberger les services internes et les services DMZ sur des environnements virtualisés.
- Relier le Site B aux Sites A et C au moyen de VPN IPsec site à site.
- Assurer la disponibilité des services Web par répartition de charge et distribution des instances entre sites.
- Détecter les incidents réseau, système, applicatifs, VPN et sauvegarde.
- Permettre la sauvegarde et la restauration documentées des composants critiques.
- Produire des configurations, procédures et preuves de recette exploitables.

### 3.2 Résultats attendus

À l'issue du projet :

- les équipements du Site B utilisent les réseaux et adresses définis dans ce document ;
- les flux autorisés fonctionnent et les flux interdits sont bloqués et journalisés ;
- le Site B échange avec les Sites A et C uniquement par les tunnels IPsec prévus ;
- les services Web restent disponibles lors de la perte d'une instance, sous réserve des objectifs de disponibilité validés ;
- les services, équipements et tunnels sont supervisés ;
- les sauvegardes sont exécutées et au moins une restauration est démontrée ;
- l'exploitation peut être reprise à l'aide de la documentation livrée.

## 4. Périmètre

### 4.1 Inclus

- inventaire, câblage et repérage du Site B ;
- configuration logique de R1, FW1 et SW1 ;
- VLAN, routage, ACL, pare-feu, NAT et publication contrôlée ;
- réseaux de maintenance de R1 et FW1 ;
- Wi-Fi du Site B et service DHCP associé ;
- hyperviseurs Proxmox et réseaux des machines virtuelles ;
- services AD DS, DNS, DHCP, GLPI, base de données, Zabbix, Squid et sauvegarde ;
- DNS Bind en DMZ ;
- infrastructure Web en DMZ, terminaison TLS, équilibrage et contrôles de santé ;
- VPN IPsec entre le Site B et les autres sites ;
- supervision, journaux, sauvegarde et restauration ;
- durcissement, administration et gestion des secrets ;
- migration, recette, documentation et transfert de compétences.

### 4.2 Hors périmètre

- développement des applications et des portails Web ;
- conception des écrans, parcours métier et règles fonctionnelles applicatives ;
- adressage détaillé ou configuration interne des Sites A et C ;
- achat de matériel non prévu dans le lab ;
- exposition directe sur Internet de RDP, SSH, DNS, Proxmox, des backends Web ou des interfaces d'administration ;
- activation d'IPv6 sans plan d'adressage, de routage et de filtrage dédié ;
- déclaration de conformité ou de bon fonctionnement sans test sur les équipements réels.

## 5. Principes d'architecture

### 5.1 Topologie logique du Site B

```text
Internet / réseau amont
          |
      R1 TP-Link
 WAN/NAT  | 172.16.1.193/30
          |
          | Transit R1-FW1 : 172.16.1.192/30
          |
 FW1 Hillstone : 172.16.1.194/30
     |                         |
     | e0/1                    | e0/2
     | 172.16.3.65/26          | 172.16.1.197/30
     |                         |
 DMZ 172.16.3.64/26       SW1 Cisco L3 : 172.16.1.198/30
                               |
                 VLAN 10 / 20 / 30 / 40 / 50 / 99
```

- **R1** assure l'accès WAN, le NAT de sortie et la première étape de la publication HTTPS.
- **FW1** sépare et filtre l'amont, le LAN et la DMZ.
- **SW1** réalise le routage inter-VLAN, porte les SVI et applique les ACL de proximité.
- Le lien FW1-SW1 est un lien routé non étiqueté ; aucun trunk n'est prévu.
- Chaque pont Proxmox transporte uniquement le réseau local auquel il est raccordé.
- SW2 reste en réserve et ne fait pas partie de la topologie cible actuelle.

### 5.2 Exigences générales d'architecture

| ID | Exigence | Priorité | Critère d'acceptation |
| --- | --- | --- | --- |
| INF-ARCH-01 | Le Site B doit utiliser exclusivement le plan d'adressage Site B validé. | Must | Aucun réseau historique n'apparaît dans les configurations actives. |
| INF-ARCH-02 | Les fonctions LAN, DMZ, amont, administration et maintenance doivent être séparées. | Must | Les zones et interfaces sont distinctes et les tests de cloisonnement réussissent. |
| INF-ARCH-03 | Le routage inter-VLAN doit être assuré par SW1. | Must | Les SVI sont actives et les routes empruntent SW1. |
| INF-ARCH-04 | Le filtrage entre le LAN, la DMZ et l'amont doit être assuré par FW1. | Must | Les compteurs de règles et les journaux montrent les autorisations et refus attendus. |
| INF-ARCH-05 | Toute configuration doit pouvoir être restaurée à partir d'une sauvegarde exportée. | Must | Un export lisible et une procédure de restauration sont livrés. |
| INF-ARCH-06 | Les paramètres non connus ne doivent pas être remplacés par des valeurs fictives. | Must | Les éléments non relevés figurent dans le registre des points ouverts. |

## 6. Inventaire matériel et câblage

### 6.1 Inventaire connu

| Quantité | Équipement | Repère / usage |
| ---: | --- | --- |
| 4 | PC Dell | PC01 à PC03 postes clients ; PC04 utilisé comme hôte Proxmox interne |
| 1 | Serveur ProLiant | Hôte Proxmox de la DMZ |
| 1 | Routeur TP-Link | R1, modèle et version à relever |
| 1 | Pare-feu Hillstone | FW1, modèle et version StoneOS à relever |
| 1 | Switch Cisco | SW1, fonctions L3 requises, modèle et IOS à relever |
| 1 | Switch Zyxel | SW2 en réserve, absent de la cible actuelle |
| 1 | Point d'accès Netis | AP1, modèle et version à relever |
| 9 | Câbles Ethernet | Catégories et longueurs à relever |
| 4 | Claviers | Connectiques à relever |
| 3 | Souris | Connectiques à relever |
| 3 | Écrans | Modèles et entrées vidéo à relever |
| 3 | Câbles vidéo | Trois VGA et un DVI inventoriés ; affectations à vérifier |
| 9 | Éléments d'alimentation | Six cordons 10 A / 240 V à vérifier, un bloc 19,5 V et deux blocs 12 V |

Les étiquettes des équipements et alimentations doivent être relevées avant branchement. Les références PC04/SRV1 de l'ancien inventaire ne doivent pas créer d'ambiguïté : ce document emploie **Proxmox Dell interne** et **ProLiant DMZ**.

### 6.2 Plan de câblage cible

| Câble | Liaison | Usage |
| --- | --- | --- |
| C01 | R1 port 4 - FW1 e0/0 | Transit 172.16.1.192/30 |
| C02 | Réseau amont - R1 port 1 | WAN à relever |
| C03 | FW1 e0/2 - SW1 port 24 | Transit 172.16.1.196/30, lien routé non étiqueté |
| C04 | FW1 e0/1 - ProLiant DMZ | Pont Proxmox DMZ non étiqueté |
| C05 | SW1 port 1 - PC01 | VLAN 10 Direction |
| C06 | SW1 port 5 - PC02 | VLAN 20 Comptabilité |
| C07 | SW1 port 15 - PC03 | VLAN 40 Administration |
| C08 | SW1 port 10 - AP1 | VLAN 30 Wi-Fi, AP en mode pont |
| C09 | SW1 port 22 - Proxmox Dell interne | VLAN 50 Serveurs |

Les deux réseaux de maintenance R1 et FW1 doivent rester physiquement séparés l'un de l'autre et du LAN. Aucun bouclage artificiel ne doit être créé pour maintenir une SVI active.

## 7. Plan d'adressage du Site B

### 7.1 Réseaux

| Zone | Réseau | Passerelle / interfaces | Plage utile ou réserve | Broadcast |
| --- | --- | --- | --- | --- |
| VLAN 10 - Direction | 172.16.1.0/27 | SW1 172.16.1.1 | .2 à .30 | 172.16.1.31 |
| VLAN 20 - Comptabilité | 172.16.1.32/27 | SW1 172.16.1.33 | .34 à .62 | 172.16.1.63 |
| VLAN 30 - Wi-Fi | 172.16.1.64/27 | SW1 172.16.1.65 | DHCP .67 à .94 ; AP .66 | 172.16.1.95 |
| VLAN 40 - Administration | 172.16.1.96/27 | SW1 172.16.1.97 | .98 à .126 | 172.16.1.127 |
| VLAN 50 - Serveurs | 172.16.1.128/27 | SW1 172.16.1.129 | fixes .130 à .135 ; réserve .136 à .158 | 172.16.1.159 |
| VLAN 99 - Management | 172.16.1.160/27 | SW1 172.16.1.161 | maintenance .162 ; réserve .163 à .190 | 172.16.1.191 |
| Transit R1-FW1 | 172.16.1.192/30 | R1 .193 ; FW1 .194 | aucune | 172.16.1.195 |
| Transit FW1-SW1 | 172.16.1.196/30 | FW1 .197 ; SW1 .198 | aucune | 172.16.1.199 |
| Réserve LAN | 172.16.1.200/29 | aucune | réservée | 172.16.1.207 |
| Réserve LAN | 172.16.1.208/28 | aucune | réservée | 172.16.1.223 |
| Gestion locale R1 | 172.16.1.224/28 | R1 172.16.1.226 | poste .227 proposé | 172.16.1.239 |
| Gestion locale FW1 | 172.16.1.240/28 | FW1 172.16.1.241 | poste .242 proposé | 172.16.1.255 |
| DMZ | 172.16.3.64/26 | FW1 172.16.3.65 | fixes/réserve .66 à .82 ; pool .83 à .126 | 172.16.3.127 |

Masques : `/27` = `255.255.255.224`, `/30` = `255.255.255.252`, `/28` = `255.255.255.240`, `/26` = `255.255.255.192`.

Il est interdit de configurer une route globale `172.16.1.0/24` vers SW1, car ce bloc contient aussi les transits et les réseaux de maintenance. Les plages disponibles ne sont pas des étendues DHCP implicites.

### 7.2 Hôtes et services fixes

| Hôte / service | Adresse cible | Passerelle | Exigence |
| --- | --- | --- | --- |
| Proxmox Dell interne | 172.16.1.130/27 | 172.16.1.129 | Hôte des VM internes |
| Windows Server | 172.16.1.131/27 | 172.16.1.129 | AD DS, DNS, DHCP et GLPI |
| Base de données | 172.16.1.132/27 | 172.16.1.129 | Moteur et port à définir |
| Zabbix | 172.16.1.133/27 | 172.16.1.129 | Supervision centralisée |
| Squid | 172.16.1.134/27 | 172.16.1.129 | Mode et port à définir |
| Sauvegarde Proxmox | 172.16.1.135/27 | 172.16.1.129 | Hébergement et stockage à définir |
| Serveur Web interne | 172.16.3.70/26 | 172.16.3.65 | Aucun DNAT direct |
| DNS Bind DMZ | 172.16.3.71/26 | 172.16.3.65 | Aucun DNAT DNS |
| Load balancer Nginx | 172.16.3.72/26 | 172.16.3.65 | Point de terminaison TLS |
| Web1 | 172.16.3.80/26 | 172.16.3.65 | Backend local prévu par la version 1.1 |
| Web2 | 172.16.3.81/26 | 172.16.3.65 | Backend local prévu par la version 1.1 |
| Web3 | 172.16.3.82/26 | 172.16.3.65 | Backend local prévu par la version 1.1 |
| ProLiant DMZ | À attribuer entre .66 et .79, hors .70 à .72 | 172.16.3.65 | Attribution obligatoire avant déploiement |
| PC01 Direction | 172.16.1.2/27 | 172.16.1.1 | Réservation proposée à contrôler |
| PC02 Comptabilité | 172.16.1.34/27 | 172.16.1.33 | Réservation proposée à contrôler |
| PC03 Administration | 172.16.1.98/27 | 172.16.1.97 | Source d'administration principale |
| AP1 | 172.16.1.66/27 | 172.16.1.65 | Mode pont, DHCP désactivé |
| Poste temporaire VLAN 99 | 172.16.1.162/27 | 172.16.1.161 | Maintenance de SW1 |

Les réservations proposées doivent être vérifiées libres. Toute IP fixe attribuée dans une plage disponible doit être retirée de cette plage avant usage.

## 8. VLAN, commutation et routage

### 8.1 Affectation des ports de SW1

| Ports SW1 | VLAN / fonction | État attendu |
| --- | --- | --- |
| 1 à 4 | VLAN 10 Direction | Port 1 actif ; autres ports arrêtés tant qu'ils ne sont pas approuvés |
| 5 à 9 | VLAN 20 Comptabilité | Port 5 actif ; autres ports arrêtés tant qu'ils ne sont pas approuvés |
| 10 à 14 | VLAN 30 Wi-Fi | Port 10 actif ; autres ports arrêtés tant qu'ils ne sont pas approuvés |
| 15 à 18 | VLAN 40 Administration | Port 15 actif ; autres ports arrêtés tant qu'ils ne sont pas approuvés |
| 19 à 22 | VLAN 50 Serveurs | Port 22 actif ; autres ports arrêtés tant qu'ils ne sont pas approuvés |
| 23 | VLAN 99 Management | Lien actif nécessaire au fonctionnement de la SVI selon le modèle |
| 24 | Transit routé vers FW1 | `172.16.1.198/30`, sans trunk |

### 8.2 Routes obligatoires

| Équipement | Destination | Prochain saut |
| --- | --- | --- |
| SW1 | 0.0.0.0/0 | 172.16.1.197 |
| FW1 | Les six réseaux VLAN /27 | 172.16.1.198 |
| FW1 | 0.0.0.0/0 | 172.16.1.193 |
| R1 | Les six réseaux VLAN /27 | 172.16.1.194 |
| R1 | 172.16.1.196/30 | 172.16.1.194 |
| R1 | 172.16.3.64/26 | 172.16.1.194 |
| R1 | 0.0.0.0/0 | Passerelle WAN à relever |

Les réseaux de gestion locale de R1 et FW1 ne doivent pas être annoncés dans le routage intersite. Les routes directement connectées ne doivent pas être recréées en statique.

### 8.3 Exigences de commutation et de routage

| ID | Exigence | Priorité | Vérification |
| --- | --- | --- | --- |
| INF-NET-01 | Chaque port d'accès doit appartenir à un seul VLAN non étiqueté. | Must | Contrôle de la configuration et test depuis un poste. |
| INF-NET-02 | Les ports non utilisés doivent être administrativement arrêtés. | Must | État `shutdown` contrôlé. |
| INF-NET-03 | La SVI VLAN 99 doit rester accessible depuis les seules sources d'administration autorisées. | Must | PC03/.162 autorisés ; PC01 refusé. |
| INF-NET-04 | Le relais DHCP du VLAN 30 doit cibler 172.16.1.131. | Must | Un client Wi-Fi reçoit un bail correct. |
| INF-NET-05 | Le réseau Wi-Fi ne doit pas atteindre les autres réseaux privés, hors DNS et DHCP nécessaires. | Must | Tests négatifs LAN, DMZ, management et privés. |
| INF-NET-06 | Les flux retour nécessaires doivent être explicitement prévus dans les ACL sans état. | Must | DNS, DHCP et ICMP autorisés fonctionnent dans les deux sens requis. |

## 9. VPN IPsec multisite

### 9.1 Cible

Le Site B doit être relié aux Sites A et C par un VPN IPsec site à site. La topologie définitive, en maillage complet ou en étoile, doit être validée selon les capacités des équipements et le site retenu comme point central. Aucune adresse des Sites A ou C ne doit être inventée dans la configuration du Site B.

Le plan actuel du dépôt attribue :

- Site A : LAN `172.16.0.0/24`, DMZ `172.16.3.0/26` ;
- Site B : LAN subdivisé dans `172.16.1.0/24`, DMZ `172.16.3.64/26` ;
- Site C : LAN `172.16.2.0/24`, DMZ `172.16.3.128/26`.

Pour le Site B, les sélecteurs locaux doivent être définis réseau par réseau : les six VLAN /27 et, seulement si nécessaire, la DMZ `172.16.3.64/26`. Les réseaux de transit et de maintenance sont exclus des domaines chiffrés.

### 9.2 Exigences IPsec

| ID | Exigence | Priorité | Critère d'acceptation |
| --- | --- | --- | --- |
| INF-VPN-01 | Les communications intersites doivent être chiffrées par IPsec. | Must | Aucun flux intersite en clair n'est observé. |
| INF-VPN-02 | IKEv2 doit être privilégié ; les suites cryptographiques obsolètes doivent être interdites. | Must | Paramètres IKE/IPsec conformes à la politique validée. |
| INF-VPN-03 | Les secrets prépartagés éventuels ne doivent pas être stockés dans Git. | Must | Aucun secret n'est présent dans le dépôt. |
| INF-VPN-04 | Les routes et sélecteurs doivent couvrir uniquement les réseaux approuvés. | Must | Aucun transit ni réseau de maintenance n'est annoncé. |
| INF-VPN-05 | Le NAT doit être exempté pour les flux intersites. | Must | Les adresses privées sources sont conservées à travers le tunnel. |
| INF-VPN-06 | Le pare-feu doit appliquer le moindre privilège entre les sites. | Must | Seuls les services inscrits dans la matrice de flux passent. |
| INF-VPN-07 | La disponibilité, la latence, la perte de paquets et les changements d'état des tunnels doivent être supervisés. | Must | Une coupure simulée produit une alerte horodatée. |
| INF-VPN-08 | Le rétablissement du tunnel doit être automatique après une coupure WAN courte. | Should | Le tunnel revient sans intervention et les services reprennent. |
| INF-VPN-09 | Les paramètres DPD, durées de vie, renouvellement et MTU/MSS doivent être documentés. | Must | La fiche VPN contient les valeurs validées et les résultats de test. |

Restent à définir avant mise en œuvre : adresses WAN des pairs, équipement portant IPsec sur chaque site, topologie, authentification, algorithmes, groupes Diffie-Hellman, durées de vie, domaines chiffrés distants, routage statique ou dynamique et stratégie de secours.

## 10. Sécurité réseau et matrice de flux

### 10.1 Principes

- politique de refus par défaut ;
- autorisation explicite par source, destination, protocole et port ;
- suivi de session sur FW1 ;
- journalisation des refus significatifs et des actions d'administration ;
- séparation des comptes utilisateur, technique et administrateur ;
- administration WAN, UPnP et ouvertures automatiques désactivés sur R1 ;
- aucune règle temporaire conservée sans justification, propriétaire et date d'expiration ;
- pare-feu local actif sur les hyperviseurs et les VM pour les flux qui ne traversent ni FW1 ni les ACL inter-VLAN.

### 10.2 Matrice minimale des flux

| Source | Destination | Service autorisé | Règle |
| --- | --- | --- | --- |
| VLAN 30 | Windows .131 | DNS TCP/UDP 53 ; DHCP UDP 68 vers 67 | Autoriser uniquement ces besoins privés |
| Relais SW1 VLAN 30 .65 | Windows .131 | DHCP UDP 67 | Autoriser requêtes et réponses nécessaires |
| VLAN 10/20 et PC03 | Windows .131 | DNS, AD, GLPI HTTPS | Autoriser selon les rôles retenus |
| Clients du domaine | Windows .131 | TCP 88, 135, 389, 445, 464, 3268, 49152-65535 ; UDP 88, 123, 389, 464 ; ICMP | Autoriser pour le fonctionnement AD validé |
| PC03 .98 | Équipements, hyperviseurs et VM inventoriés | SSH 22, HTTPS 443, Proxmox 8006, RDP 3389, WinRM 5986, ADWS 9389 selon besoin | Limiter à l'administration |
| Windows .131 | Base .132 | Port du moteur à définir | Refuser toute autre source inutile |
| Zabbix .133 | Agents | TCP 10050 ; TCP 10051 selon le mode | Limiter aux hôtes supervisés |
| Clients autorisés | Squid .134 | Port du proxy à définir | Wi-Fi exclu tant que ce flux n'est pas prévu dans le lab |
| VLAN 10/20 et PC03 | Load balancer .72 | HTTPS 443 | Autoriser |
| Windows .131 | Bind .71 | DNS TCP/UDP 53 | Autoriser |
| Load balancer .72 | Backends Web | HTTP TCP 80 ou port applicatif validé | Autoriser, y compris via VPN si backend distant |
| Site B | Réseaux A/C approuvés | Services intersites documentés | Autoriser dans IPsec uniquement |
| DMZ | LAN | Retours de sessions permises uniquement | Refuser toute nouvelle session |
| VLAN 30 | Réseaux privés | Aucun hors DNS/DHCP prévus | Refuser et journaliser |
| Serveurs autorisés | DNS/NTP externes approuvés | DNS TCP/UDP 53 ; NTP UDP 123 | Listes d'adresses explicites |
| LAN/DMZ autorisés | Internet | HTTPS TCP 443 | HTTP 80 uniquement sur exception limitée et validée |

La matrice définitive doit préciser les flux entre Sites A, B et C, notamment ceux nécessaires aux annuaires, à la supervision, aux sauvegardes, aux deux services Web et à l'administration globale.

## 11. NAT et publication

### 11.1 Cible locale validée

| Équipement | Entrée | Traduction |
| --- | --- | --- |
| R1 | Réseaux LAN/DMZ autorisés vers le WAN | SNAT/PAT sur l'adresse WAN |
| R1 | WAN TCP 443 | DNAT vers FW1 172.16.1.194:443 |
| FW1 | AMONT TCP 443 correspondant à la publication | DNAT vers le load balancer 172.16.3.72:443 |

La prise en charge par R1 du NAT des réseaux routés doit être vérifiée. Si elle est impossible, une variante SNAT sur FW1 pourra être étudiée et documentée ; elle ne doit pas être appliquée sans validation.

### 11.2 Interdictions

- aucun DNAT TCP 80 ;
- aucun DNAT vers .70, .71, .80, .81 ou .82 ;
- aucune publication de SSH, RDP, DNS, Proxmox, hyperviseur ou interface d'administration ;
- aucun SNAT entre le LAN et la DMZ ;
- aucun NAT des flux protégés par le VPN IPsec.

Une adresse WAN privée ne garantit pas une accessibilité depuis Internet. Toute publication en amont du Site B doit être identifiée et validée séparément.

## 12. Wi-Fi et DHCP

AP1 doit fonctionner en point d'accès ponté sur le VLAN 30. Son propre service DHCP doit être désactivé. L'isolation entre clients, le chiffrement Wi-Fi, les identifiants de réseau et la politique de rotation des secrets doivent être définis avant ouverture aux utilisateurs.

L'étendue DHCP du Site B doit être créée sur `172.16.1.131` avec les paramètres suivants :

| Paramètre | Valeur |
| --- | --- |
| Réseau | 172.16.1.64/27 |
| Plage | 172.16.1.67 à 172.16.1.94 |
| Passerelle, option 003 | 172.16.1.65 |
| DNS, option 006 | 172.16.1.131 |
| Bail | 8 heures |
| Exclusions | réseau .64, passerelle .65, AP .66, broadcast .95 |

La nouvelle étendue doit être préparée inactive. L'ancienne étendue doit être sauvegardée et désactivée avant l'activation de la nouvelle. Aucun service DHCP ne doit être activé sur les réseaux serveurs, DMZ, transits ou maintenance.

## 13. Virtualisation et services internes

### 13.1 Hyperviseurs

- Le Proxmox Dell interne utilise `172.16.1.130/27`, passerelle `.129`, sur un pont non étiqueté raccordé au port 22 de SW1.
- Le ProLiant DMZ utilise un pont non étiqueté raccordé à FW1 e0/1. Son IP de gestion doit être attribuée dans `.66-.79`, hors `.70-.72`, avant tout déploiement.
- Les interfaces de gestion des hyperviseurs ne doivent pas être publiées sur Internet.
- Les accès Proxmox doivent être limités à PC03 et aux sources d'administration approuvées.
- Les comptes nominatifs, le MFA si disponible, la synchronisation NTP et la journalisation doivent être activés.
- Les ressources CPU, mémoire, stockage et réseau doivent être dimensionnées après inventaire des charges.
- Les instantanés ne doivent pas être considérés comme des sauvegardes.

### 13.2 Services du VLAN 50

| Service | Exigences d'infrastructure |
| --- | --- |
| AD DS / DNS / DHCP / GLPI | Domaine réel à renseigner ; clients configurés sur DNS .131 ; rôle DHCP autorisé ; sauvegarde état système et données GLPI |
| Base de données | Moteur, port, capacité, comptes de service, chiffrement, sauvegarde cohérente et restauration à définir |
| Zabbix | Supervision des trois sites, équipements, hyperviseurs, VM, services Web, VPN, stockage et sauvegardes |
| Squid | Port, mode, authentification, règles et journaux à définir ; aucun accès Wi-Fi implicite |
| Sauvegarde Proxmox | Support, capacité, rétention, isolation, chiffrement et copie hors site à définir |

### 13.3 DNS

- Les clients du domaine utilisent le DNS Windows `172.16.1.131`.
- Bind `172.16.3.71` peut être utilisé comme résolveur pour les requêtes externes si ce rôle est confirmé.
- La récursion Bind doit être limitée à Windows `.131` et aux hôtes DMZ autorisés.
- Bind ne doit pas être publié sur Internet.
- Les zones directes et inverses doivent être tenues à jour après réadressage.
- Les noms internes des services Web doivent pointer directement vers les adresses ou points d'entrée internes et ne pas dépendre d'un hairpin NAT non défini.

## 14. Hébergement Web et haute disponibilité

### 14.1 Services à héberger

L'infrastructure doit supporter **deux services Web internes distincts**. Leur rôle fonctionnel détaillé relève du cahier des charges Web. La séparation suivante est retenue comme base technique :

1. un service Web interne sur `172.16.3.70`, non publié directement ;
2. un service Web distribué derrière le load balancer `172.16.3.72`, avec terminaison TLS et contrôles de santé.

Le portail ou service d'administration doit rester accessible uniquement depuis le VLAN 40 et, si ce parcours est mis en place dans le lab, depuis un VPN d'administration. Il ne doit pas être placé dans le vhost exposé au WAN.

### 14.2 État local prévu par le schéma Site B

La version 1.1 du schéma réserve trois backends locaux :

- Web1 `172.16.3.80:80` ;
- Web2 `172.16.3.81:80` ;
- Web3 `172.16.3.82:80`.

Nginx sur `.72` termine TLS 1.2/1.3 et répartit les requêtes. Les backends doivent accepter HTTP uniquement depuis `.72` et depuis leur boucle locale pour le diagnostic. Un contrôle `/healthz` doit être disponible sans exposer d'information sensible.

### 14.3 Cible multisite de haute disponibilité

Le besoin global prévoit des instances Web réparties sur les trois sites. La cible doit donc permettre au Site B d'héberger au moins une instance locale et de joindre, via IPsec, les instances homologues des Sites A et C.

Le plan actuel `.80-.82` décrit trois backends dans la DMZ du Site B. La transformation de cette cible locale en une répartition réellement multisite constitue une modification d'architecture à valider. Elle devra préciser :

- quelle adresse locale du Site B représente son backend ;
- les adresses des backends A et C ;
- les routes et règles IPsec correspondantes ;
- la méthode de répartition globale : load balancer central, load balancers par site, DNS avec contrôles de santé ou autre mécanisme ;
- le comportement en cas de perte d'un backend, d'un tunnel ou d'un site complet ;
- la réplication des données, le stockage partagé éventuel et la gestion des sessions ;
- la cohérence des certificats et des noms DNS ;
- le mode dégradé accepté et la procédure de retour à l'état nominal.

### 14.4 Exigences de disponibilité

| ID | Exigence | Priorité | Critère d'acceptation |
| --- | --- | --- | --- |
| INF-HA-01 | Une instance Web défaillante doit être retirée automatiquement du pool. | Must | Le contrôle de santé échoue et aucune nouvelle requête ne lui est envoyée. |
| INF-HA-02 | Les instances restantes doivent continuer à servir les requêtes lors de la perte d'un backend. | Must | Test de panne concluant sans erreur durable côté client. |
| INF-HA-03 | La perte du backend du Site B ne doit pas rendre indisponible le service distribué si les VPN et les autres sites fonctionnent. | Must | Bascule vers une instance A ou C démontrée. |
| INF-HA-04 | Les sessions utilisateur ne doivent pas dépendre d'un fichier local unique. | Must | Une bascule conserve la session ou force une reconnexion maîtrisée selon le choix validé. |
| INF-HA-05 | Les données persistantes doivent avoir une stratégie de réplication et de sauvegarde cohérente. | Must | Test de reprise et absence de corruption démontrés. |
| INF-HA-06 | Les points uniques de panne doivent être recensés. | Must | Registre couvrant R1, FW1, SW1, LB, DNS, base, stockage, hyperviseurs et WAN. |
| INF-HA-07 | Le load balancer `.72`, actuellement unique, doit être redondé ou son risque résiduel formellement accepté. | Must | Second nœud/VIP testé ou acceptation signée. |
| INF-HA-08 | Le lab doit fixer des objectifs de reprise mesurables pour pouvoir tester la continuité. | Should | Temps de reprise et perte de données observée consignés pendant les essais. |
| INF-HA-09 | La supervision doit distinguer panne applicative, panne d'hôte, perte VPN et perte de site. | Should | Chaque panne simulée produit l'alerte correcte. |

La présence de trois serveurs Web sur un même hyperviseur ou un même site ne constitue pas à elle seule une haute disponibilité multisite.

## 15. Administration et accès distants

### 15.1 Administration locale

- PC03 utilise normalement `172.16.1.98/27`, passerelle `.97`, DNS `.131` sur le VLAN 40.
- Pour R1, PC03 peut être raccordé temporairement au port 5 avec `.227/28`, sans passerelle, afin d'administrer `.226`.
- Pour FW1, PC03 peut être raccordé temporairement à e0/3 avec `.242/28`, sans passerelle, afin d'administrer `.241`.
- Après maintenance, PC03 doit être remis en `.98/27` sur SW1 port 15.
- SW1 est administré par SSH via la SVI VLAN 99 `.161`, depuis `.98` ou le poste de maintenance `.162` seulement.
- Les lignes VTY ne portent aucune adresse IP ; toutes les plages VTY du modèle doivent recevoir la même restriction d'accès.

### 15.2 Exigences d'accès distant

- Aucun RDP ni SSH ne doit être publié directement sur Internet.
- L'accès distant utilisateur doit passer par une solution chiffrée, une authentification multifacteur et une passerelle contrôlant la destination autorisée.
- L'accès distant d'administration doit utiliser un profil VPN distinct ou un bastion approuvé, limité aux sources et équipements autorisés.
- Toutes les ouvertures et fermetures de session doivent être horodatées et centralisées.
- Les comptes partagés permanents sont interdits ; les comptes de secours doivent être protégés et leur usage audité.

## 16. Durcissement et gestion des secrets

| ID | Exigence | Priorité |
| --- | --- | --- |
| INF-SEC-01 | Les mots de passe, clés privées, secrets IPsec et jetons ne doivent jamais être versionnés dans Git. | Must |
| INF-SEC-02 | Les équipements et systèmes doivent utiliser des versions maintenues et recevoir les correctifs de sécurité selon une procédure approuvée. | Must |
| INF-SEC-03 | SSH doit utiliser des clés et des algorithmes approuvés ; Telnet doit être désactivé. | Must |
| INF-SEC-04 | Les interfaces d'administration doivent être limitées aux réseaux dédiés. | Must |
| INF-SEC-05 | Les services inutiles, comptes par défaut et ouvertures automatiques doivent être désactivés. | Must |
| INF-SEC-06 | Les horloges doivent être synchronisées sur des sources NTP approuvées. | Must |
| INF-SEC-07 | Les certificats doivent couvrir les noms DNS utilisés, être renouvelables et protéger leur clé privée. | Must |
| INF-SEC-08 | Les configurations et règles temporaires doivent être revues après chaque intervention. | Must |
| INF-SEC-09 | Un scan de la surface exposée doit confirmer que seul le service autorisé est accessible. | Must |
| INF-SEC-10 | Les changements sensibles doivent être associés à un ticket, un auteur, une date et un plan de retour arrière. | Must |

## 17. Supervision, journalisation et alertes

Zabbix `172.16.1.133` est la solution retenue dans le lab pour centraliser la supervision des trois sites.

### 17.1 Éléments à superviser

- disponibilité et ressources de R1, FW1, SW1 et AP1 ;
- état des ports, erreurs, saturation et changements de topologie ;
- disponibilité, latence et perte des tunnels IPsec ;
- CPU, RAM, stockage, interfaces et état des hyperviseurs ;
- disponibilité et ressources des VM ;
- AD DS, DNS, DHCP, GLPI, base de données, Squid et Bind ;
- load balancer, certificat TLS, `/healthz` et chaque backend Web ;
- échecs de sauvegarde et capacité du stockage ;
- expiration des certificats, indisponibilité NTP et erreurs DNS.

### 17.2 Journaux minimaux

- authentifications réussies et échouées ;
- changements de configuration réseau, système et sécurité ;
- connexions VPN, changements d'état IPsec et accès distants ;
- décisions du pare-feu et refus significatifs ;
- actions d'administration sur les hyperviseurs et VM ;
- état des sauvegardes et restaurations ;
- changements de pool et contrôles de santé du load balancer.

Chaque événement doit contenir une date synchronisée, l'équipement ou le service, l'identité ou le compte technique, l'adresse source, l'action et son résultat. Les journaux doivent être centralisés, protégés contre l'altération, sauvegardés et conservés pendant une durée à valider.

## 18. Sauvegarde, restauration et continuité

### 18.1 Éléments à sauvegarder

- exports des configurations R1, FW1, SW1 et AP1 ;
- configurations IPsec, règles de pare-feu et objets réseau, sans exposer les secrets ;
- configurations des hyperviseurs et inventaire des VM ;
- état système AD, zones DNS, DHCP et données GLPI ;
- base de données et fichiers nécessaires à sa restauration cohérente ;
- configurations Zabbix, Squid, Bind, Nginx et certificats selon une procédure sécurisée ;
- contenu et données des deux services Web ;
- documentation d'exploitation et matrice de flux.

### 18.2 Exigences

- définir une politique de rétention, un support et une capacité ;
- conserver au moins une copie séparée de l'hyperviseur et du site protégé ;
- chiffrer les sauvegardes contenant des données sensibles ;
- limiter les droits de suppression et d'altération ;
- superviser chaque tâche et alerter en cas d'échec ;
- tester périodiquement une restauration dans un environnement isolé ;
- mesurer et consigner le RPO et le RTO obtenus ;
- documenter le redémarrage ordonné des dépendances après sinistre.

## 19. Déploiement et migration

### 19.1 Prérequis

- relever les modèles, versions, licences, interfaces et accès console ;
- relever le WAN et la passerelle de R1 ;
- attribuer l'IP de l'hyperviseur DMZ ;
- confirmer le domaine AD, les DNS, les NTP et les noms des services Web ;
- confirmer les ports de la base, de Squid et les modes Zabbix ;
- sauvegarder les configurations et VM existantes ;
- préparer les certificats et secrets hors du dépôt ;
- valider les paramètres VPN avec les Sites A et C ;
- établir un plan de retour arrière complet.

### 19.2 Ordre de déploiement recommandé

1. Sauvegarder, inventorier, étiqueter et vérifier les accès locaux.
2. Configurer les interfaces, transits et routes de R1, FW1 et SW1.
3. Créer les VLAN, les SVI, les ports d'accès et le VLAN de management.
4. Migrer les hyperviseurs et les hôtes vers leurs adresses cibles.
5. Mettre en service DNS et DHCP sans activer prématurément la nouvelle étendue.
6. Déployer Bind, le serveur Web interne et les premiers backends DMZ.
7. Appliquer les ACL, les pare-feu hôtes et les règles FW1.
8. Configurer et tester les tunnels IPsec et leurs routes de retour.
9. Déployer les autres backends et la répartition de charge multisite.
10. Installer le load balancer, TLS et les contrôles de santé.
11. Mettre en service supervision, centralisation des journaux et sauvegardes.
12. Exécuter les tests positifs, négatifs, de panne et de restauration.
13. Activer la publication TCP 443 en dernier, après validation de tous les contrôles.
14. Exporter les configurations finales et remettre le dossier d'exploitation.

Les anciennes adresses, routes, étendues et ACL doivent être remplacées de manière cohérente, et non simplement conservées en parallèle. Les listes de règles ne doivent pas être fusionnées sans analyse de leur ordre et de leur effet.

## 20. Recette

### 20.1 Recette réseau locale

| ID | Test | Résultat attendu |
| --- | --- | --- |
| REC-NET-01 | SW1 vers FW1 .197 et FW1 vers R1 .193 | Voisins joignables avec les masques /30 corrects |
| REC-NET-02 | Routage des six VLAN | Routes aller et retour correctes, sans route globale /24 vers SW1 |
| REC-NET-03 | DHCP Wi-Fi | Bail .67-.94, /27, GW .65, DNS .131 ; aucune attribution .65, .66 ou .95 |
| REC-NET-04 | DNS et domaine depuis VLAN 10/20 | Résolution, adhésion, session et stratégies fonctionnelles |
| REC-NET-05 | Wi-Fi vers réseaux privés | Refus hors DNS/DHCP autorisés |
| REC-NET-06 | Administration SW1 | PC03/.162 autorisés en SSH ; PC01 refusé |
| REC-NET-07 | Réseaux de maintenance R1/FW1 | Accès local séparé ; aucune route entre les deux segments |
| REC-NET-08 | Ports inutilisés | Ports arrêtés et absence de connexion non autorisée |

### 20.2 Recette VPN et intersite

| ID | Test | Résultat attendu |
| --- | --- | --- |
| REC-VPN-01 | Établissement Site B - Site A | Tunnel IKE/IPsec actif et paramètres conformes |
| REC-VPN-02 | Établissement Site B - Site C | Tunnel IKE/IPsec actif et paramètres conformes |
| REC-VPN-03 | Flux autorisé entre sites | Service joignable avec adresse source privée conservée |
| REC-VPN-04 | Flux intersite non autorisé | Refus et journalisation |
| REC-VPN-05 | Réseaux de maintenance/transit | Non joignables et absents des sélecteurs |
| REC-VPN-06 | Coupure puis retour WAN | Alerte, tunnel rétabli et reprise des flux |
| REC-VPN-07 | MTU/MSS et charge | Pas de fragmentation bloquante ni perte anormale |

### 20.3 Recette Web, sécurité et haute disponibilité

| ID | Test | Résultat attendu |
| --- | --- | --- |
| REC-WEB-01 | HTTPS vers le load balancer | TLS valide ; aucun accès HTTP public |
| REC-WEB-02 | Accès du load balancer aux backends | HTTP ou port retenu accessible depuis `.72` uniquement en local |
| REC-WEB-03 | Accès direct d'un client à un backend | Refus |
| REC-WEB-04 | Arrêt d'un backend | Retrait automatique et continuité via les instances restantes |
| REC-WEB-05 | Perte du backend Site B | Bascule vers un backend A ou C via IPsec |
| REC-WEB-06 | Perte d'un tunnel | Alerte et comportement conforme au mode dégradé validé |
| REC-WEB-07 | Serveur interne .70 | Accessible seulement depuis les sources internes autorisées, sans DNAT |
| REC-SEC-01 | Scan WAN | Seul TCP 443 autorisé est visible ; aucun SSH, RDP, DNS, Proxmox ou backend |
| REC-SEC-02 | Nouvelle session DMZ vers LAN | Refus et journalisation ; retours autorisés préservés |
| REC-SEC-03 | Administration du portail/service sensible | Disponible uniquement depuis VLAN 40 ou VPN d'administration approuvé |

### 20.4 Recette systèmes, supervision et sauvegarde

| ID | Test | Résultat attendu |
| --- | --- | --- |
| REC-SYS-01 | Services AD/DNS/DHCP/GLPI | Services actifs et dépendances documentées |
| REC-SYS-02 | Base, Squid, Bind et Zabbix | Ports nécessaires autorisés, autres flux refusés |
| REC-MON-01 | Incident simulé sur équipement, VM, VPN et Web | Alerte correcte, horodatée et affectée |
| REC-LOG-01 | Action administrative | Journal central contenant source, identité, action et résultat |
| REC-BKP-01 | Exécution d'une sauvegarde | Tâche réussie, contrôlée et supervisée |
| REC-BKP-02 | Restauration en environnement isolé | Service restauré et temps mesuré |
| REC-OPS-01 | Redémarrage | Configurations persistantes et tests essentiels toujours concluants |

Chaque test doit conserver : date, opérateur, source, destination, commande ou scénario, résultat attendu, résultat observé, preuve, anomalie et décision.

## 21. Livrables

- cahier des charges d'infrastructure validé ;
- schéma physique et logique à jour du Site B ;
- plan d'adressage et inventaire des réservations ;
- inventaire matériel, câblage et étiquetage ;
- configurations finales et exports de R1, FW1, SW1 et AP1 ;
- dossier de configuration VPN IPsec et matrice des flux intersites ;
- dossier des hyperviseurs, VM, ressources et dépendances ;
- configurations des services internes et DMZ ;
- dossier de haute disponibilité des deux services Web ;
- dossier de certificats sans clé privée dans la documentation ;
- configuration de supervision, seuils, tableaux de bord et notifications ;
- politique et procédure de sauvegarde/restauration ;
- procédure de gestion des comptes, secrets et accès d'administration ;
- procédure de migration, retour arrière et reprise après incident ;
- procès-verbal de recette avec preuves ;
- dossier d'exploitation et transfert de compétences.

## 22. Risques et mesures de réduction

| Risque | Impact | Mesure attendue |
| --- | --- | --- |
| Paramètres WAN ou modèles inconnus | Blocage ou erreur de configuration | Relevé préalable et validation constructeur |
| Réutilisation de l'ancien adressage | Conflit, panne ou défaut de sécurité | Utiliser uniquement la version 1.1 et contrôler les configurations |
| Route globale 172.16.1.0/24 vers SW1 | Détournement des transits et de la maintenance | Routes explicites vers les six /27 |
| Mauvais sélecteurs IPsec | Réseau inaccessible ou exposition excessive | Liste approuvée, tests positifs et négatifs |
| Asymétrie de routage entre sites | Sessions interrompues | Vérification des routes retour avant NAT supplémentaire |
| Toutes les instances Web sur un seul site/hyperviseur | Fausse haute disponibilité | Répartition effective A/B/C et test de perte de site |
| Load balancer unique | Indisponibilité du point d'entrée | Redondance ou acceptation formelle du risque |
| Base ou stockage unique | Perte de service ou de données | Réplication, sauvegarde et test de restauration |
| Secret présent dans Git | Compromission | Gestionnaire de secrets et rotation immédiate en cas de fuite |
| Règle de pare-feu trop large | Mouvement latéral ou exposition | Refus par défaut, revue et journalisation |
| Sauvegarde non restaurable | Perte durable | Tests périodiques et mesures RPO/RTO |
| SVI VLAN 99 inactive | Perte de gestion SW1 | Lien approuvé actif sur port 23 et procédure console |
| Dépendance au hairpin NAT | Accès interne instable | DNS interne pointant vers l'entrée interne appropriée |
## 23. Paramètres techniques à définir avant le montage

1. modèles, versions et noms réels des interfaces ;
2. paramètres WAN de R1 et possibilité de NAT des réseaux routés ;
3. équipement portant les VPN IPsec, topologie et paramètres cryptographiques ;
4. adresses WAN et domaines chiffrés exacts des Sites A et C ;
5. matrice des flux intersites ;
6. IP de gestion du ProLiant DMZ ;
7. maintien opérationnel de la SVI VLAN 99 et besoin d'un câble/poste permanent ;
8. domaine AD, groupes, zones DNS, résolveurs et sources NTP ;
9. noms et usages exacts des deux services Web internes ;
10. URL, certificats et autorité de certification utilisée dans le lab ;
11. répartition exacte des backends Web entre A, B et C ;
12. mécanisme global de répartition et de bascule ;
13. stratégie des sessions, données et fichiers partagés entre instances Web ;
14. redondance du load balancer, de DNS, de la base et du stockage ;
15. moteur et port de base de données ;
16. mode, port et politique de Squid ;
17. mode agent/serveur/proxy Zabbix et seuils d'alerte ;
18. hébergement, capacité et rétention du service de sauvegarde `.135` ;
19. objectifs de reprise, de latence et de capacité à tester ;
20. durée de conservation des journaux dans le lab ;
21. solution d'accès distant, MFA et bastion/passerelle ;
22. plan IPv6 si IPv6 doit être activé.

## 24. Gestion des modifications du lab

Avant une modification importante du plan d'adressage, des zones, des flux, de la publication, des VPN ou de la haute disponibilité :

1. noter le changement prévu et son impact ;
2. sauvegarder la configuration concernée ;
3. préparer un retour arrière ;
4. réaliser les essais utiles ;
5. mettre à jour la documentation avec le résultat observé.

## 25. Références internes au dépôt

- [Présentation générale du projet](../../../README.md)
- [Présentation du Site B](../../README.md)
- [Schéma réseau Site B version 1.1](../docs/Schéma/SITE_B_Schema.pdf)
- [Dossier technique du réseau Site B](../docs/Dossier_reseau.md)
- [Statut des documents d'infrastructure](../docs/README.md)
- [Index des configurations du Site B](../configuration/README.md)
- [Configuration cible de SW1](../configuration/Network/SW1.conf)
- [Paramètres de R1 et FW1](../configuration/Network/R1_FW1.md)
- [Paramètres des hôtes et services](../configuration/Servers/Services.md)
- [Mémo de déploiement DMZ](../configuration/Servers/DMZ/memo_ordre_déploiement.md)
- [Cahier des charges Web du Site B](../../Application-Web/CDC/CDC_yanis.md)
- [Expression de besoin à trois sites](../../../Site-A/Application-Web/Cahier%20des%20Charges/CDC-Projet_fil_rouge-Robin.pdf)

---

**Fin du cahier des charges - version 0.1**
