# Cahier des charges — Site C
## Portail web sécurisé et intégration à l’infrastructure multisite

| Information | Valeur |
| --- | --- |
| Projet | Projet Fil Rouge — Infrastructure multisite |
| Périmètre de cette version | Site C ; sites A et B distants |
| Dépôt / branche | NovaTech91/Projet-Fil-Rouge — `ilyes` |
| Version | 1.1 Markdown consolidée — correction du site et alignement sur le dépôt local |
| Date | 6 octobre 2026 |
| Statut | Proposition enrichie à valider ; aucune réalisation ou recette n’est attestée par ce document |
| Coordination | Ilyes, chef de projet ; équipe Ilyes, Yves et Alain ; ajouts de missions à confirmer |

> Ce document reprend le cahier des charges Site C fourni par Ilyes et le complète avec la cible décrite dans le projet local. Les besoins du PDF sont conservés ; les évolutions réseau du dépôt sont identifiées explicitement. Le document décrit une cible à valider et ne constitue pas une preuve de déploiement.

## Sommaire

1. [Sources et règles de consolidation](#1-sources-et-règles-de-consolidation)
2. [Objectif, utilisateurs et périmètre](#2-objectif-utilisateurs-et-périmètre)
3. [État documentaire et architecture du site C](#3-état-documentaire-et-architecture-du-site-c)
4. [Exigences fonctionnelles](#4-exigences-fonctionnelles)
5. [Profils, droits et périmètres](#5-profils-droits-et-périmètres)
6. [Écrans et parcours](#6-écrans-et-parcours)
7. [Conception et intégrations](#7-conception-et-intégrations)
8. [Flux réseau et accès distant](#8-flux-réseau-et-accès-distant)
9. [Données et traçabilité](#9-données-et-traçabilité)
10. [Exigences non fonctionnelles](#10-exigences-non-fonctionnelles)
11. [Sauvegardes et exploitation](#11-sauvegardes-et-exploitation)
12. [Réalisation, responsabilités et livrables](#12-réalisation-responsabilités-et-livrables)
13. [Recette](#13-recette)
14. [Risques et décisions à valider](#14-risques-et-décisions-à-valider)
15. [Validation](#15-validation)

## 1. Sources et règles de consolidation

### 1.1 Documents utilisés

- **PDF fourni par Ilyes** : `Cahier_des_charges_Site_C_actualise.pdf`, version 1.3 du 25 septembre 2026, 10 pages. Il définit les besoins, les exigences F01 à F11, la matrice des droits, les missions et la recette. Le PDF a été fourni séparément et n’est pas présumé présent dans ce dossier.
- [Présentation de l’application web du site C](../README.md).
- [Plan d’adressage actuel du site C](../../Infrastructure/README.md).
- [Architecture et fonctionnement](../../Infrastructure/docs/Dossier_reseau.md).
- [Configuration du switch L3](../../Infrastructure/configuration/Switch-L3.txt).
- [Pare-feu Hillstone et routes R1](../../Infrastructure/configuration/Pare-feu-Hillstone.md).
- [Audit du site C](../../Infrastructure/docs/Audit_Site_C.md).

Les fichiers locaux du projet, branche `ilyes`, ont été consultés le 6 octobre 2026. Ils décrivent une cible plus récente que le PDF pour le réseau.

### 1.2 Évolutions du PDF vers la cible locale

| Sujet | PDF Site C v1.3 | Cible actuelle du dépôt local |
| --- | --- | --- |
| Séparation des réseaux | R2 entre proxy et LAN | Hillstone à quatre interfaces WAN/LAN/PROXY/CAMERAS ; aucun R2 |
| Caméras | VLAN 70 sur le switch L3 | Interface dédiée Hillstone ; aucun VLAN caméra sur le switch |
| Proxy | Passerelle .161 portée par R2 | Passerelle 172.16.3.161 portée par Hillstone |
| Transit du switch | Lien direct vers R1 sur 192.168.0.0/30 | Switch–Hillstone : 172.16.2.192/30 ; R1–Hillstone : 192.168.0.0/30 |
| Réserve LAN | Bloc 172.16.2.192/27 entièrement libre | .192–.195 utilisés pour le transit ; .196–.223 non attribués |
| HA | Trois nœuds et stockage à définir | Cluster à préparer, réplication ZFS des VM LAN prévue ; bascule à tester |
| Invités | Internet uniquement, exception Web à arbitrer | Proxy 80/443 permis dans la cible documentée ; arbitrage métier toujours nécessaire |

Les exigences **F01 à F11 reprennent la numérotation du PDF Site C**. F12 ajoute une proposition de gestion du cycle de vie des habilitations. Les compléments restent soumis à validation de l’équipe et de la cliente.

## 2. Objectif, utilisateurs et périmètre

### 2.1 Finalité

Mettre à disposition un portail accessible par navigateur qui centralise :

- les annonces et les services autorisés pour chaque salarié ;
- le profil personnel et les demandes d’assistance ;
- l’accès sécurisé à la VM attribuée pour les personnes habilitées au travail distant ;
- le traitement des tickets et la traçabilité des interventions ;
- les informations de supervision et de sauvegarde nécessaires aux équipes habilitées ;
- une vue multisite adaptée au rôle et au périmètre de chaque utilisateur.

Exemple : un salarié se connecte, consulte ses services, accède à sa VM après MFA, puis ouvre un ticket en cas de problème. Le technicien de son périmètre traite la demande et documente le résultat. Un besoin de droits supplémentaires est transmis à un administrateur habilité.

### 2.2 Périmètre inclus

Le portail, ses intégrations à l’annuaire, aux tickets, à la supervision et à l’accès distant ; les règles réseau nécessaires ; la maquette ; les sauvegardes applicatives ; les procédures ; les tests et preuves de recette. L’infrastructure prévue du site C sert de socle : VLAN, routage, pare-feu, DNS, DHCP, virtualisation, DMZ et services.

Le nom définitif de l’entreprise, son activité, les effectifs par site, les utilisateurs simultanés et le nombre de télétravailleurs restent à confirmer. Les confirmer avec la cliente.

### 2.3 Limites

- Pas de console publique donnant un accès libre au réseau ou aux hyperviseurs.
- Pas de RDP, SSH, interface Proxmox, base de données ou annuaire directement publié sur Internet.
- Pas de modification de son propre rôle, site ou périmètre par un salarié.
- VoIP, Wi-Fi, caméras et cluster font partie du périmètre infrastructure Site C ; leur présence n’impose pas de développer une console de commande pour chaque équipement dans le portail.
- L’étude IA évoquée dans le PDF fourni reste facultative, hors du socle, sans action automatique sur le réseau.
- Une maquette avec données fictives ne vaut pas intégration fonctionnelle.

## 3. État documentaire et architecture du site C

### 3.1 Cible et état de réalisation

Le dépôt décrit deux serveurs web sur Proxmox 1, un reverse proxy sur Proxmox 2 et trois hôtes Proxmox dans le VLAN 30. Le README applicatif précise que la configuration applicative et les certificats restent à déployer. La présence de configurations ou de dossiers Front-End/Back-End ne prouve pas le fonctionnement du portail ; seuls les tests et preuves datés permettent de déclarer un lot réalisé.

### 3.2 Réseaux de référence

| VLAN / zone | Réseau | Passerelle / fonction |
| --- | --- | --- |
| 10 — Service 1 | 172.16.2.0/27 | Switch : 172.16.2.1 |
| 20 — Service 2 | 172.16.2.32/27 | Switch : 172.16.2.33 |
| 30 — Serveurs / Proxmox | 172.16.2.64/27 | Switch : 172.16.2.65 |
| 40 — Wi-Fi employés | 172.16.2.96/27 | Switch : 172.16.2.97 |
| 50 — VoIP | 172.16.2.128/27 | Switch : 172.16.2.129 |
| 60 — Wi-Fi invités | 172.16.2.160/27 | Switch : 172.16.2.161 |
| 99 — Management | 172.16.2.224/27 | Switch : 172.16.2.225 |
| Transit switch–Hillstone | 172.16.2.192/30 | Switch .193 ; Hillstone .194 |
| Réserve | 172.16.2.196 à .223 | Non attribuée ; découpage futur à définir |
| Caméras | 172.16.3.128/27 | Hillstone : 172.16.3.129 |
| Proxy DMZ | 172.16.3.160/27 | Hillstone : 172.16.3.161 |
| Transit R1–Hillstone | 192.168.0.0/30 | R1 .1 ; Hillstone WAN .2 |

Les /27 utilisent le masque 255.255.255.224, les /30 le masque 255.255.255.252. La réserve contient 28 adresses non attribuées, pas 28 adresses hôtes garanties : les réseaux et broadcasts dépendront du découpage futur. Les ports et le câblage détaillés restent décrits dans le dossier réseau.

### 3.3 Services et hébergement

| Hôte / service | Adresse prévue | Hébergement / passerelle |
| --- | --- | --- |
| AD / DNS / DHCP | 172.16.2.66/27 | VM LAN, placement à définir ; passerelle .65 |
| Zabbix | 172.16.2.67/27 | VM LAN, placement à définir ; passerelle .65 |
| Proxmox 1 | 172.16.2.72/27 | Gestion VLAN 30 ; passerelle .65 |
| Proxmox 2 | 172.16.2.68/27 | Gestion VLAN 30 ; passerelle .65 |
| Proxmox 3 | 172.16.2.73/27 | Gestion VLAN 30 ; passerelle .65 |
| Web 1 | 172.16.2.69/27 | Proxmox 1 ; passerelle .65 |
| Web 2 | 172.16.2.71/27 | Proxmox 1 ; passerelle .65 |
| Reverse proxy | 172.16.3.162/27 | Proxmox 2, bridge DMZ ; passerelle 172.16.3.161 |
| IPBX prévu | 172.16.2.130/27 | VLAN 50 ; passerelle 172.16.2.129 |
| Caméras | 172.16.3.130 à .158/27 | Réseau dédié ; passerelle 172.16.3.129 |

Les IP .72/.73 sont à vérifier avant déploiement. Exclure toutes les adresses fixes des baux DHCP.

Proxmox 2 utilise deux cartes et deux bridges séparés : gestion LAN sur la première ; bridge DMZ sans IP de l’hôte sur la seconde, relié uniquement à la VM proxy. Ne jamais ponter LAN et DMZ. Les interfaces proxy et caméras du Hillstone sont distinctes et non taguées.

### 3.4 Trajet web et limites

Client → switch L3 → Hillstone → reverse proxy .162 → Hillstone → switch L3 → Web 1 .69 ou Web 2 .71. Le DNS interne du portail doit pointer vers le proxy. Les noms DNS, certificats et paramètres opérateur restent à définir.

Le switch route et filtre les échanges inter-VLAN ; Hillstone filtre les échanges entre WAN, LAN, proxy et caméras. Les échanges dans un même VLAN nécessitent des pare-feu locaux lorsque leur isolation est requise.

Deux serveurs web peuvent servir une même application. Tous deux étant initialement hébergés sur Proxmox 1, leur duplication ne protège pas à elle seule contre la panne de cet hôte. Le rôle applicatif précis de chaque serveur et le placement du backend, de la base, de l’identité/MFA et de la passerelle VM restent à valider.

## 4. Exigences fonctionnelles

F01 à F11 sont les exigences conservées du PDF Site C. Les critères précisent leur vérification ; ils ne prouvent pas leur réalisation. Tout report de fonction nécessite un arbitrage explicite.

| ID | Exigence | Résultat attendu |
| --- | --- | --- |
| F01 | Accueil salarié et tableau de bord administrateur | Annonces et état des seuls services autorisés ; sites, serveurs, VM, VPN et alertes selon périmètre administrateur |
| F02 | Profil | Nom, prénom, e-mail professionnel, agence, fonction/rôle, photo facultative ; modification limitée aux champs personnels autorisés, jamais rôle/agence/droits |
| F03 | Réinitialisation de mot de passe | Demande tracée, identité vérifiée, décision et opération réalisées par un administrateur habilité ; aucun secret dans le ticket |
| F04 | Contrôle des accès | Profils Direction, Administrateur, Technicien, Employé ; vérification côté serveur pour chaque opération et ressource, y compris URL/API directes |
| F05 | Poste virtuel personnel | Travail distant avec MFA puis accès uniquement à la VM attribuée et aux ressources métier autorisées ; RDP/SSH non publiés directement |
| F06 | Demandes de services et droits | Ouverture après validation administrative ; connexions, demandes et modifications de droits journalisées |
| F07 | Tickets | Numéro, demandeur, agence, date/heure, catégorie, description, priorité, technicien et statut ; historique au moins jusqu’à clôture ; salarié limité à ses demandes |
| F08 | Interventions et périmètres | Auteur, date, service/équipement, motif et résultat ; technicien et administrateur locaux limités à leur périmètre ; vue globale réservée à l’administrateur global |
| F09 | Supervision | Détection indisponibilité équipements/serveurs/VM, arrêt Web, coupure VPN, CPU/RAM/disque et échec sauvegardes ; alerte et retour à la normale |
| F10 | Informations et documentation | Infrastructure, sauvegardes, incidents et documentation consultables selon les droits |
| F11 | Maquette | Validation des écrans et parcours avant développement ; espaces salarié, technicien et administrateur distincts |
| F12 | Cycle de vie des habilitations — complément proposé | Arrivée, changement de rôle/site, départ, retrait de VM et révocation des accès traités et vérifiés |

## 5. Profils, droits et périmètres

Matrice reprise du PDF Site C et précisée pour les contrôles applicatifs, à faire valider. Une fonction métier « Direction » n’attribue pas automatiquement un rôle technique. Une habilitation administrative supplémentaire doit être explicite, de préférence avec un compte distinct.

| Action / ressource | Employé | Direction | Technicien | Administrateur |
| --- | --- | --- | --- | --- |
| Profil et services personnels | Soi | Soi | Soi | Soi et gestion habilitée |
| Modifier son rôle, site ou ses droits | Non | Non | Non | Pas d’auto-attribution non approuvée |
| VM personnelle | Uniquement attribuée | Uniquement attribuée | Attribuée ; diagnostic séparément habilité | Attribution et administration habilitées |
| Créer et suivre ses tickets | Oui | Oui | Oui | Oui |
| Traiter les tickets d’autrui | Non | Non par défaut | Périmètre affecté | Périmètre local ou global |
| Valider un droit / réinitialiser | Demande uniquement | Demande uniquement | Transmission | Habilitation explicite |
| Synthèse métier | Non | Synthèse autorisée | Selon mission | Selon habilitation |
| Diagnostic et documentation technique | Aides utilisateur | Aides et synthèse | Périmètre | Périmètre local ou global |
| Accès direct à Zabbix | Non | Non par défaut | Non par défaut | Habilité uniquement |
| Configurer réseau / hyperviseurs | Non | Non | Non par défaut | Canal d’administration sécurisé |
| Journaux techniques / audit | Non ; suivi de ses demandes | Synthèse autorisée | Actions utiles au périmètre | Habilitation d’audit |

L’appartenance à un VLAN ou la possession d’un lien ne remplace pas les autorisations applicatives. Les filtres par site et propriétaire s’appliquent aussi aux recherches, exports, commentaires, pièces jointes et statistiques.

## 6. Écrans et parcours

### 6.1 Écrans à maquetter

| Espace | Écrans / contenu |
| --- | --- |
| Commun | Connexion, MFA, accueil, aide de récupération d’accès, accès refusé, service indisponible |
| Salarié | Mon profil, Mes services, Ma machine virtuelle, Assistance, Mes tickets et détail d’un ticket |
| Technicien | Tickets du périmètre, prise en charge, historique d’intervention, diagnostic autorisé, documentation |
| Administrateur | Tableau de bord, Utilisateurs, Agences, demandes de droits, Réseau, VPN, VM, Serveurs, Supervision, Sauvegardes, Documentation et audit |
| Direction | Services personnels et synthèse métier validée, sans commandes techniques par défaut |

Les pages Réseau, VPN, VM et Serveurs présentent les informations utiles et, si nécessaire, un accès au canal dédié. Elles ne constituent pas une autorisation de lancer des commandes arbitraires depuis le portail.

### 6.2 Parcours salarié et VM

Connexion → vérification du compte et des droits → accueil personnalisé → sélection de la VM attribuée → MFA vérifié avant ouverture distante → session autorisée → déconnexion.

Prévoir les cas : aucune VM attribuée, VM arrêtée, MFA perdu, identité indisponible et habilitation retirée. La passerelle doit refuser une VM non attribuée même si son identifiant est connu.

### 6.3 Parcours ticket

Création → qualification → affectation → prise en charge → intervention documentée → résolution → clôture. Statuts proposés : **Nouveau, Qualifié, En cours, En attente, Résolu, Clos** ; réouverture tracée.

Chaque changement conserve l’auteur, l’horodatage, l’ancien et le nouveau statut. Le salarié consulte ses échanges publics ; les notes techniques internes restent réservées au support habilité. Les priorités, règles d’escalade, délais et modalités de clôture sont à convenir.

### 6.4 Droits et réinitialisation

Une demande de droits précise le service, le motif, le site, le bénéficiaire et, si pertinent, la durée. Un administrateur habilité valide ou refuse ; l’exécution et le contrôle du résultat sont des étapes distinctes.

Une réinitialisation exige une vérification d’identité via une procédure définie. Prévoir un canal d’assistance vérifié pour le salarié qui ne peut plus se connecter : le portail authentifié ne peut pas être son unique recours. La récupération du MFA suit également une procédure vérifiée et journalisée. Aucun mot de passe, code de récupération ou jeton n’est placé dans les tickets.

## 7. Conception et intégrations

### 7.1 Choix à effectuer

| Brique | Exigence / base prévue | Décision attendue |
| --- | --- | --- |
| Interface web | Espaces par profil, navigateur, formulaires et tableaux de bord | Choisir les composants adaptés aux compétences ; aucune technologie imposée par le PDF Site C |
| Backend | Contrôle des droits, demandes, accès aux données | Langage/framework, hébergement et dépendances à définir |
| Identité / MFA | AD prévu, MFA externe obligatoire | Définir fournisseur, protocoles, groupes et certificats ; MFA administrateur proposé en complément |
| Accès VM | Seule VM attribuée accessible | Comparer passerelle web avec MFA et VPN utilisateur avec MFA ; prototype avant choix |
| Assistance | Tickets avec historique et périmètres | Comparer outil dédié et module sur mesure ; aucun outil de tickets imposé à ce stade |
| Supervision | Zabbix reste le socle prévu | Définir informations lisibles par rôle et fréquence de mise à jour |
| Base applicative | Données du portail et intégrations | Moteur, capacité, emplacement, comptes et sauvegarde à définir |

Les outils applicatifs seront sélectionnés après comparaison et prototype. Leur choix pour le site C doit être justifié et validé.

### 7.2 Architecture logique

Navigateur → reverse proxy HTTPS → application du portail → services autorisés (identité, tickets, supervision, stockage). L’accès à la VM utilise une passerelle ou un VPN utilisateur contrôlé, avec vérification de la ressource attribuée.

- L’interface présente les pages ; le backend protège les données et vérifie les autorisations.
- L’annuaire / fournisseur d’identité est la référence des comptes ; pas de copie des mots de passe AD dans le portail.
- Si un outil de tickets dédié est retenu, définir une seule référence des tickets et leur synchronisation ; éviter deux historiques divergents.
- Zabbix fournit les états ; une source indisponible doit produire un état inconnu ou périmé, jamais un faux état sain.
- Si les deux Web servent la même application, définir sessions, fichiers partagés, versions et déploiement cohérents.
- Les identifiants d’intégration restent côté serveur avec les seuls droits nécessaires ; aucun jeton d’administration dans le navigateur.

### 7.3 Fiches de déploiement

Avant installation, produire une fiche par composant : hôte, zone, IP vérifiée libre, nom DNS, CPU/RAM/disque, ports, dépendances, compte de service, sauvegarde et méthode de mise à jour. Les adresses des composants non documentés restent à attribuer ; ne pas inventer une base ou un fournisseur d’identité déjà installé.

## 8. Flux réseau et accès distant

### 8.1 Politique et besoins à compléter

Le proxy est autorisé vers Web 1 et Web 2 sur les ports HTTP/HTTPS retenus. Cette permission n’autorise pas automatiquement les flux nécessaires à l’identité, aux tickets, à la base ou à une passerelle VM. Les composants placés dans le même VLAN 30 doivent aussi être filtrés sur les hôtes si nécessaire.

Les documents locaux signalent notamment que les flux AD complets, DNS/mises à jour du proxy, publication publique et protocole réel des caméras restent à définir. Détailler chaque besoin avant de modifier une règle, sans autorisation globale vers le LAN.

### 8.2 Matrice des flux

| Source | Destination | Service / état |
| --- | --- | --- |
| VLAN 10/20/40 | Reverse proxy 172.16.3.162 | HTTPS ; HTTP uniquement selon redirection retenue ; accès décrit dans la cible |
| VLAN 60 invités | Reverse proxy .162 | 80/443 permis dans la cible locale ; exception à arbitrer par rapport au besoin Internet uniquement |
| Proxy .162 | Web .69 et .71 | HTTP/HTTPS selon application ; passage obligatoire par Hillstone |
| Clients autorisés | AD/DNS/DHCP .66 | DNS/DHCP prévus ; flux AD nécessaires à compléter et tester |
| Backend / identité | Annuaire et autres services nécessaires | Source, destination, protocole chiffré, port et compte à définir |
| Backend | Tickets / Zabbix / base applicative | APIs et ports selon outils retenus ; comptes à droits minimaux |
| Passerelle distante | VM attribuées | Protocole privé retenu ; destinations et droits individuels limités |
| VLAN 99 | Équipements, hyperviseurs, proxy et caméras | Administration habilitée selon politiques ; journalisation |
| Caméras | DNS .66 / Zabbix .67 | DNS et Zabbix actif TCP 10051 décrits ; vérifier le support réel des équipements |
| Sites A/B | Services du site C | VPN, réseaux sans chevauchement, routes retour et refus à définir |

Chaque règle précise source, destination, protocole, port, sens, retours attendus, justification et preuve de test. Les ACL Cisco avec `established` ne constituent pas un suivi complet de session ; le Hillstone assure le filtrage à états entre ses zones.

### 8.3 Publication et VPN

Les nouvelles connexions Internet vers les réseaux internes sont refusées dans la politique décrite. L’accès externe du portail reste à préparer : adresse et paramètres opérateur, DNS, certificats, NAT/publication via R1 et Hillstone, puis proxy comme point d’entrée web. Tester depuis un réseau externe réel.

Ne pas publier directement RDP, SSH, Proxmox, l’annuaire, les bases ou les consoles techniques. Distinguer le VPN intersite A/B/C du VPN utilisateur éventuel. Ni un tunnel ni un compte authentifié ne donnent accès à toutes les VM.

## 9. Données et traçabilité

### 9.1 Modèle minimal proposé

| Objet | Données / relations minimales |
| --- | --- |
| Utilisateur | Identifiant annuaire stable, nom, prénom, e-mail, site, statut ; pas de copie du mot de passe AD |
| Site / rôle / habilitation | Identifiant, périmètre, bénéficiaire, valideur, dates et expiration éventuelle |
| Ressource / attribution VM | Identifiant technique, site, bénéficiaire autorisé, dates d’attribution et de retrait |
| Ticket | Identifiant de référence, demandeur, site, catégorie, description, priorité, statut, affectation, dates |
| Intervention / commentaire | Ticket, auteur, date, visibilité, service/équipement, motif, résultat |
| Demande de droits | Bénéficiaire, droit demandé, justification, décision, valideur, exécution et résultat |
| Annonce / documentation | Titre, contenu ou lien, auteur, version, date, audience autorisée |
| Événement d’audit | Auteur ou système, action, ressource, date, résultat et identifiant de corrélation |

Éviter de recopier l’intégralité des données de ticketing/Zabbix si une référence contrôlée suffit. Définir la responsabilité de chaque donnée et le comportement en cas de divergence.

### 9.2 Journalisation et confidentialité

Horloges synchronisées ; événements attribuables ; accès aux journaux limité ; durées de conservation et procédure de purge à définir. Conserver l’historique des tickets au moins jusqu’à leur clôture, puis selon la durée approuvée.

Ne jamais journaliser les mots de passe, codes MFA, cookies de session ou jetons. Utiliser des données fictives ou anonymisées pour les maquettes et preuves diffusées.

Les pièces jointes sont une extension à valider : si retenues, définir types et tailles autorisés, contrôle de contenu, stockage protégé et vérification des droits à chaque téléchargement.

## 10. Exigences non fonctionnelles

| ID | Exigence | Critère / statut |
| --- | --- | --- |
| NF01 | MFA | Obligatoire pour accès distant ; extension aux comptes administrateurs proposée ; récupération et révocation testées |
| NF02 | Confidentialité des échanges | HTTPS et certificats cohérents ; chiffrement des flux d’identité, de données sensibles et d’administration ; aucun secret en clair |
| NF03 | Traçabilité | Chaque action sensible de recette produit une trace horodatée et attribuable |
| NF04 | Isolation | Aucun RDP/SSH public ; interfaces techniques réservées aux accès habilités |
| NF05 | Performance | Complément proposé, non imposé par le PDF Site C : écrans principaux en ≤ 2 s ; préciser postes, réseau, volume de données, concurrence et méthode de mesure |
| NF06 | Alertes | Complément proposé, non imposé par le PDF Site C : alertes visibles en ≤ 2 min ; préciser point de départ, collecte et rafraîchissement ; mesurer panne et retour |
| NF07 | Disponibilité | Objectif, plage de service et durée d’observation à définir ; aucune promesse de HA implicite |
| NF08 | Ergonomie | Parcours cohérents pour les quatre profils, libellés français, erreurs compréhensibles |
| NF09 | Sécurité applicative — complément | Validation des entrées, prévention injections/XSS/CSRF selon architecture, cookies protégés, limitation des essais, expiration des sessions et contrôles serveur |
| NF10 | Accessibilité — complément | Navigation clavier, champs étiquetés, focus visible, contrastes lisibles et affichage mobile ; contrôle sur navigateurs retenus |
| NF11 | Défaillances des intégrations — complément | État inconnu/périmé affiché avec horodatage ; message utile ; pas de faux succès ni de fuite technique |
| NF12 | Maintenabilité — complément | Installation reproductible, dépendances versionnées, configuration séparée des secrets et procédure de retour arrière |

Les seuils proposés ne deviennent des critères d’engagement qu’après validation du contexte de mesure. Les capacités CPU, RAM, stockage et le nombre de VM simultanées doivent être mesurés avant dimensionnement définitif.

## 11. Sauvegardes et exploitation

Sauvegarder les données applicatives, tickets, configurations d’identité/MFA, bases, documents, configurations du proxy et des services, ainsi que les éléments nécessaires à la restauration des VM. Protéger séparément les secrets et clés indispensables à la reprise.

Définir fréquence, rétention, copie séparée des hôtes de production, chiffrement, droits de restauration et alertes d’échec. Un snapshot ne remplace pas une sauvegarde indépendante.

Avant validation, effectuer une restauration dans un environnement isolé, vérifier une connexion et un ticket complet, puis mesurer :

- **RTO** : durée nécessaire pour remettre le service en fonctionnement ;
- **RPO** : quantité de données potentiellement perdue, exprimée en durée.

Aucune valeur RTO/RPO n’est encore approuvée. Trois nœuds ne suffisent pas à déclarer la HA opérationnelle : vérifier quorum, watchdog, stockage, réplication ZFS prévue, ressources disponibles après panne et bascule des VM LAN. Documenter les pannes de chaque Proxmox, du proxy, de l’identité et de la base. Le réseau DMZ du proxy ne rejoint initialement que Proxmox 2 : sa bascule automatique sur un autre nœud n’est pas acquise. Prévoir sa restauration ; une extension DMZ isolée aux autres nœuds est une évolution à concevoir. La copie cloud de sauvegarde ne remplace pas la réplication.

Prévoir une procédure de déploiement : sauvegarde préalable, contrôle de configuration, migration de données, tests de santé et parcours, puis retour arrière cohérent du code et des données en cas d’échec. Le simple résultat de `/healthz` ne prouve pas le fonctionnement des tickets, de l’identité ou de la base.

## 12. Réalisation, responsabilités et livrables

### 12.1 Calendrier et missions du PDF

| Sprint | Travaux et responsables | Validation attendue |
| --- | --- | --- |
| 1 | Équipe : câblage et architecture ; annoncé réalisé dans le PDF | Schéma, photos et inventaire à conserver ; adaptation à la cible Hillstone à vérifier |
| 2 | Ilyes : VLAN, routage et premiers tests ; annoncé réalisé | Configurations et preuves ; vérifier l’adaptation aux nouveaux transits et DMZ |
| 3 — jusqu’à décembre 2026 | Ilyes : adressage et ACL ; Ilyes/Yves : Proxmox et HA ; Yves : Internet, pare-feu, sauvegardes et Zabbix ; Alain : AD/DNS/DHCP, postes, Web, VoIP, Wi-Fi et caméras | Répartition issue du PDF à confirmer pour la cible sans R2 ; prototype proxy/cluster et services |
| 4 — janvier/février 2027 | Ilyes : coordination, isolation, recette ; Yves : VPN, restauration, bascule ; Alain : droits, services, tableaux de bord et fiches ; équipe : corrections | Tests datés, preuves, procédures de reprise et soutenance |

Les missions R2 de l’ancien PDF sont remplacées par les besoins de segmentation Hillstone ; leur répartition exacte reste à valider. « Annoncé réalisé » ne remplace pas une preuve.

### 12.2 Lots applicatifs proposés

| Lot | Travaux | Condition de fin |
| --- | --- | --- |
| L0 | Cadrage, matrice des droits, dimensionnement, budget et choix | CDC et décisions approuvés |
| L1 | Maquette des espaces et parcours, y compris erreurs/refus | Validation avant développement |
| L2 | Identité, MFA, HTTPS et flux minimaux | Prototype authentifié et filtrage testé |
| L3 | Profil et ticket de bout en bout | Salarié → technicien → salarié vérifié |
| L4 | Demandes de droits et accès distant à la VM attribuée | Validation, refus et révocation testés |
| L5 | Supervision, audit, documentation et sauvegardes | Alertes réelles et restauration démontrées |
| L6 | Recette, correction et transfert | PV, preuves et réserves enregistrés |

Estimer les lots en sprint 3 et désigner les exécutants. La responsabilité Web d’Alain ne lui attribue pas automatiquement tout le portail. Si la charge dépasse la capacité de l’équipe, faire valider un lot complémentaire plutôt que déclarer les fonctions terminées.

### 12.3 Livrables

CDC approuvé ; maquette ; matrice des droits ; schéma et plan IP ; flux ; code et configurations sans secrets ; procédures installation/mise à jour/retour arrière ; gestion des comptes et récupération d’accès ; sauvegarde/restauration ; cahier de tests et preuves ; dossier d’exploitation ; guide utilisateur et support de soutenance.

Chaque tâche porte un responsable, une échéance, ses dépendances et une preuve de fin. Organiser le développement dans Front-End/Back-End selon les outils retenus et suivre les changements sur la branche `ilyes`.

## 13. Recette

Aucun test n’est déclaré exécuté par ce CDC. Pour chaque essai : objectif, prérequis, procédure, date, opérateur, version, compte/site/source, attendu, obtenu, preuve, anomalie et retest. Les identifiants R01 à R11 conservent les domaines de recette du PDF Site C, adaptés à Hillstone.

| Test | Exigences / domaine | Réussite attendue |
| --- | --- | --- |
| R01 | Réseau | Sept VLAN /27, deux DMZ /27, transit /30 et réserve .196–.223 cohérents ; DNS/DHCP/routes vérifiés |
| R02 | Isolation / F04 | Caméras isolées, management réservé, invités selon arbitrage, refus intersites ; vérifier les interdictions |
| R03 | F01 à F04 | Quatre profils testés ; pas d’accès à autrui par URL/API/recherche ; champs rôle/agence bloqués côté serveur |
| R04 | F03 / F06 | Réinitialisation après vérification d’identité ; droits ouverts uniquement après validation ; décision et résultat tracés |
| R05 | F05 | MFA externe ; seule VM attribuée accessible ; RDP/SSH non exposés ; refus si aucune attribution |
| R06 | F07 / F08 | Création, affectation, traitement, clôture et réouverture ; historique complet et salarié limité à ses demandes |
| R07 | F08 | Technicien et administrateur locaux limités au périmètre ; canal d’administration sécurisé |
| R08 | F09 / F10 | Panne et retour VM/Web/VPN détectés ; échec sauvegarde signalé ; documentation selon droits |
| R09 | VPN / Hillstone | Tunnel, reconnexion, routes aller/retour ; proxy vers Web .69/.71 ; bridges séparés ; refus caméra/proxy/LAN vérifiés |
| R10 | Reprise / HA | Restauration vérifiée ; quorum et bascule des VM LAN éligibles testés ; durée et perte mesurées ; limite proxy explicitée |
| R11 | F11 | Maquette, parcours, architecture et nouveaux lots approuvés avant développement |
| R12 — complément | F12 | Désactivation, changement de périmètre et retrait VM ; révocation effective selon délai validé |
| R13 — complément | Sécurité / publication | Certificats/DNS corrects ; surface externe limitée ; aucune console technique accessible publiquement |
| R14 — complément | Performance / ergonomie | Charge et seuils convenus mesurés ; clavier, mobile, erreurs et parcours vérifiés |
| R15 — complément | Intégrations | Panne de l’identité, du ticketing ou de Zabbix gérée honnêtement ; pas de faux succès, droits maintenus |
| R16 — complément | Deux serveurs web | Versions et sessions cohérentes ; bascule applicative testée si prévue ; ne pas confondre panne d’une VM et panne de Proxmox 1 |

Préparer les essais perturbateurs dans un environnement de test ou une fenêtre convenue. Un test non exécuté reste en réserve ; une anomalie corrigée doit être retestée.

## 14. Risques et décisions à valider

| ID | Point | Décision attendue |
| --- | --- | --- |
| D01 | PDF antérieur à la cible Hillstone | Valider les évolutions de la section 1 ; éviter le retour aux anciennes routes R2 |
| D02 | Paramètres distants et opérateur absents | Identifier réseaux A/B, équipements, VPN, IP opérateur, routes et publication |
| D03 | Identité et accès VM | Choisir MFA, passerelle ou VPN utilisateur et procédures de récupération |
| D04 | Application / base / tickets non définis | Choisir outils, placement, capacité, adresses et responsables |
| D05 | Flux incomplets | Compléter AD, DNS et mises à jour du proxy, supervision et intégrations ; tests négatifs |
| D06 | Exception Web invités | Arbitrer Internet uniquement ou portail autorisé ; aligner CDC, ACL et tests |
| D07 | HA des VM LAN | Vérifier stockage, ZFS/réplication, quorum, watchdog et capacité après panne |
| D08 | Proxy limité à Proxmox 2 | Documenter reprise ; extension DMZ aux autres nœuds uniquement après conception et recette |
| D09 | Charge applicative | Estimer portail/tickets/MFA/VM ; ne pas confondre hébergement Web et développement |
| D10 | Exploitation | Fixer disponibilité, RTO/RPO, rétention, support, sauvegarde séparée et maintenance |
| D11 | Matériel et licences | Confirmer cartes réseau, stockage, ressources, équipements caméras/VoIP et licences nécessaires |
| D12 | Preuves de réalisation | Inventorier l’existant réel ; conserver exports et résultats datés |
| D13 | Données et effectifs | Confirmer entreprise, utilisateurs simultanés, télétravailleurs et données sensibles |
| D14 | Deuxième switch et HA proxy | Évolutions distinctes du socle ; LACP ne protège pas contre la panne du switch qui porte les passerelles |

## 15. Validation

| Élément | À renseigner |
| --- | --- |
| Version approuvée | |
| Cliente / représentante | |
| Responsable projet | |
| Responsable technique | |
| Date | |
| Décision | Approuvé / approuvé avec réserves / à réviser |
| Réserves, responsables et échéances | |
| Lien vers maquette et PV de recette | |

L’acceptation du document fixe le périmètre et les choix retenus. La mise en service dépend ensuite des résultats de recette et du traitement explicite des réserves.
