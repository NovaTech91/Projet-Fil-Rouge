# Blueprint d’implémentation du back-end du portail salarié

## 1. Objet de ce document

Ce document organise le travail nécessaire à l’implémentation du **back-end du portail salarié** décrit dans le [cahier des charges](../CDC/CDC_yanis.md). Il est destiné à l’agent ou à l’équipe qui réalisera ensuite le développement.

Il ne contient volontairement aucun code. Il fixe :

- le périmètre de la première version ;
- l’architecture logique attendue ;
- les responsabilités de chaque module ;
- les règles métier et de sécurité ;
- les contrats que le back-end devra exposer au front-end ;
- les intégrations avec les services de l’entreprise ;
- les données à conserver et leurs sources de référence ;
- les tests et preuves de recette à produire ;
- l’ordre recommandé des travaux ;
- les décisions qui doivent être validées avant de développer.

Le cahier des charges reste la source contractuelle. En cas de contradiction, ses exigences priment sur ce README. Toute modification du périmètre doit être reportée dans les deux documents et validée.

## 2. Résultat attendu

Le back-end à réaliser doit permettre à un salarié authentifié par le SSO de :

1. ouvrir une session applicative sans ressaisir son mot de passe depuis un poste joint au domaine ;
2. consulter les annonces et l’état des services qui lui sont accessibles ;
3. consulter son profil issu de l’Active Directory ;
4. modifier uniquement sa photo et les données personnelles explicitement déclarées modifiables ;
5. consulter les services autorisés selon son identité, ses groupes, son rôle et son agence ;
6. consulter sa seule affectation de machine virtuelle et demander l’ouverture d’une connexion par une passerelle sécurisée ;
7. créer et suivre ses propres tickets ;
8. demander un service ou un droit supplémentaire sans que cette demande ouvre automatiquement le droit ;
9. fermer sa session applicative.

Le back-end doit également fournir des mécanismes techniques pour :

- appliquer les autorisations côté serveur à chaque requête ;
- empêcher tout accès aux fonctions d’administration ;
- journaliser les événements de sécurité et les actions métier ;
- fonctionner derrière un reverse proxy/load balancer de confiance ;
- résister à la perte d’une instance applicative lorsque plusieurs instances sont déployées ;
- exposer des contrôles de santé sans donnée sensible ;
- dégrader proprement les fonctions dépendantes d’un service externe indisponible.

## 3. Périmètre

### 3.1 Inclus dans la V1

- SSO salarié par Kerberos/SPNEGO au niveau du fournisseur d’identité, puis OpenID Connect entre le fournisseur d’identité et l’application.
- Création, renouvellement et destruction d’une session applicative sécurisée.
- Projection des attributs utiles de l’AD sans stockage de mot de passe.
- Calcul des droits à partir des groupes AD, du rôle, de l’agence et des affectations explicites.
- Accueil personnalisé : annonces et état synthétique des services autorisés.
- Profil salarié en lecture, avec mise à jour strictement limitée aux champs autorisés.
- Gestion sécurisée de la photo de profil.
- Catalogue des services filtré par utilisateur.
- Consultation de l’affectation de VM et création d’un lancement sécurisé via Guacamole, RD Gateway ou une solution VDI validée.
- Création et suivi des tickets par intégration avec GLPI si ce choix est confirmé. V1 lien simple vers l'outil GLPI
- Création d’une demande de droit ou de service sous forme de ticket soumis à validation.
- Journalisation structurée et transmission vers la plateforme centrale de logs.
- Contrôles de santé, métriques techniques et gestion normalisée des erreurs.
- Tests automatisés fonctionnels, d’autorisation, d’intégration, de sécurité et de résilience.

### 3.2 Hors périmètre de ce back-end

- Portail d’administration, comptes administrateurs locaux et MFA par e-mail.
- Modification directe de l’AD, des groupes AD ou des droits d’un utilisateur.
- Réinitialisation automatique d’un mot de passe AD.
- Administration directe de Proxmox, des pare-feu, des commutateurs ou des serveurs.
- Publication directe de RDP, SSH, d’une console hyperviseur ou d’un secret de connexion.
- Moteur de ticketing complet si GLPI est retenu comme source de référence. Simplement inclure un lien vers l'outil GLPI
- Application mobile native.
- Automatisation d’une action technique critique.
- Exposition directe du portail sur Internet.

### 3.3 Principe de la V1

La V1 doit privilégier la **consultation**, la **mise en relation avec les services existants** (lien vers les différents outils mis en place) et les parcours à faible risque. Toute opération ayant un effet sur l’infrastructure ou sur les habilitations doit rester une demande tracée, validée puis exécutée dans le référentiel autoritaire approprié.

(Cette version est une V1 staging, la plupart des outils peuvent être "simulés" par de simples page avec quelques données factices ou des liens si les services sont hebergés ailleurs, les liens "morts" sont aussi valides)

## 4. Décisions obligatoires avant développement

Le développement ne doit pas commencer tant que les points marqués **bloquants** ne sont pas arbitrés et consignés dans une fiche de décision.

| Sujet | Décision attendue | Statut initial | Décision |
| --- | --- | --- |
| CIDR salariés | Valider la liste exacte des réseaux autorisés. Candidats Site-B : VLAN 10 `172.16.1.0/27`, VLAN 20 `172.16.1.32/27` et éventuellement VLAN 30 `172.16.1.64/27`. | Bloquant | Les réseaux autorisés sont VLAN 10 et 20 |
| VLAN Wi-Fi | Le plan réseau actuel refuse au VLAN 30 l’accès aux autres réseaux privés hors DNS/DHCP. Décider si le portail doit lui être ouvert et adapter les ACL uniquement après validation. | Bloquant | Le VLAN 30 n'a pas accès aux autres réseaux pour le moment, ouvertures si nécessaire plus tard. L'idée étant de donner aux postes du VLAN 30 accès uniquement au DHCP et proxy mis en place dans le VLAN 50 pour gérer tout accès à des resources externes |
| Publication | Confirmer que le portail salarié utilise un nom et un chemin réseau internes, accessibles aussi par le VPN d’entreprise, sans emprunter le DNAT Internet actuellement prévu vers le load balancer public. | Bloquant | Le nome retenu pour ce service interne est novatech.local/portal |
| DNS | Choisir le nom DNS interne définitif du portail salarié. | Bloquant | novatech.local/portal |
| TLS | Désigner l’autorité de certification, le propriétaire des certificats et la procédure de renouvellement. | Bloquant | à décider, besoin de recherche sur la stratégie à adopter |
| Fournisseur d’identité | Confirmer Keycloak ou un équivalent, sa haute disponibilité et son mode de fédération LDAP/Kerberos avec l’AD. | Bloquant | Keycloak retenu |
| Identité stable | Définir le claim OIDC portant l’identifiant AD immuable, de préférence dérivé de l’`objectGUID`, et interdire l’e-mail comme clé primaire. | Bloquant | à décider, besoin de recherche sur la stratégie à adopter |
| Groupes et rôles | Valider les groupes AD, les attributs d’agence, les rôles `Employé` et `Direction`, ainsi que leur mapping applicatif. | Bloquant | 5 rôles, direction, compta, technicien, admin local, admin global. tag site A, B et C pour les emplacements afin de réduire la visibilité des techniciens et des admins mais tout les employés sont taggés par leurs sites, à confirmer qu'il s'agit de la bonne stratégie, meilleurs option dans AD?
| Ticketing | Confirmer GLPI, sa version, son API, le compte technique, les catégories, priorités et statuts exposés au salarié. | Bloquant pour le lot Tickets | V1 exposer un lien mort, à compléter par la suite, avancement itératif |
| Accès VM | Choisir Guacamole, RD Gateway ou la solution VDI ; définir son API et le mécanisme de lancement temporaire. | Bloquant pour le lot VM | Exposer un lien mort, avancement itératif |
| Affectations VM | Désigner la source de référence de l’association salarié/VM et le processus de révocation lors d’un départ. | Bloquant pour le lot VM | processus géré sur le portail administrateur, donnée partagée entre les deux portails, simuler un lien mort vers les VM, avancement itératif |
| État des services | Désigner la source de l’état affiché : Zabbix, référentiel local contrôlé ou agrégateur dédié. | Bloquant pour l’accueil | artifacts factices pour V1, avancement itératif |
| Annonces | Désigner la source de publication et les critères de ciblage par agence/rôle. | Bloquant pour l’accueil | artifacts factices pour V1, avancement itératif |
| Données Direction | Définir les informations supplémentaires visibles par le rôle Direction. Aucun privilège technique ne doit être supposé. | Bloquant pour l’autorisation | artifacts factices pour V1, avancement itératif |
| Photos | Valider formats, poids, dimensions, stockage, antivirus, durée de conservation et image par défaut. | Bloquant pour la modification du profil | artifacts factices pour V1, avancement itératif |
| Sessions | Définir durée absolue, durée d’inactivité, règles de renouvellement et comportement de la déconnexion vis-à-vis du fournisseur d’identité. | Bloquant | durée absolue 6 heures, inactivité 1 heure, déconnexion du portail, reconnexion via l'AD, si question supplémentaires revenir sur ce point |
| Conservation | Valider les durées de conservation des photos, tickets, projections, caches, traces techniques et journaux d’audit. | Bloquant avant production | suggestions par modèle IA |
| Capacité | Valider le nombre d’utilisateurs simultanés et les objectifs de charge. | Bloquant avant recette de performance | 150 employés au total, capacité d'acceuil de 450 sessions concurrentes |
| Continuité | Valider RPO, RTO, fréquence des sauvegardes et procédure de restauration. | Bloquant avant production | non bloquant pour V1, revoir le point plus tard |
| Demande sans authentification | Décider si une page séparée de demande de réinitialisation de mot de passe est réellement nécessaire. Elle ne doit pas être ajoutée par défaut au portail authentifié. | À arbitrer séparément |non bloquant pour V1 |

Chaque décision doit indiquer au minimum : date, décideur, choix retenu, options rejetées, raison, impact, exigences concernées et date de réexamen éventuelle. (note pour l'IA, ce genre de d'info n'est pas utile, il s'agit d'un projet de lab, seul la décision et les raisons sont utiles)

## 5. Architecture cible

### 5.1 Chaîne de confiance

Le parcours nominal doit suivre cet ordre :

1. le poste salarié se trouve sur un réseau autorisé ou reçoit une adresse autorisée après connexion au VPN d’entreprise ;
2. les ACL du réseau et le pare-feu vérifient la source selon une politique de refus par défaut ;
3. un reverse proxy Nginx dédié au portail salarié vérifie à nouveau la source ;
4. une source refusée reçoit directement `403 Forbidden`, sans redirection vers le SSO et sans appel au back-end ;
5. Nginx termine TLS ou relaie en TLS selon l’architecture validée, écrase les en-têtes d’adresse client non fiables et transmet la requête à une instance applicative saine ;
6. le back-end déclenche ou vérifie le parcours OIDC auprès du fournisseur d’identité ;
7. le fournisseur d’identité réalise l’authentification intégrée Kerberos/SPNEGO avec l’AD ;
8. le back-end valide l’identité, calcule les droits et crée la session applicative ;
9. chaque requête métier est autorisée côté serveur avant tout accès aux données ou appel d’intégration ;
10. les événements utiles sont envoyés au stockage central de journaux.

### 5.2 Composants attendus

| Composant | Responsabilité | Contraintes |
| --- | --- | --- |
| ACL et pare-feu | Autoriser uniquement les réseaux salariés et VPN validés. | Refus par défaut ; aucun accès Internet direct. |
| Nginx salarié | TLS, filtrage CIDR, en-têtes de sécurité, limitation de débit, équilibrage et refus 403 pré-applicatif. | Configuration et secrets distincts du portail admin ; liste de proxies de confiance explicite. |
| Fournisseur d’identité | Fédération AD, Kerberos/SPNEGO et émission de jetons OIDC. | Aucun mot de passe AD transmis ou stocké par l’application. |
| Back-end salarié | Sessions, autorisations, agrégation métier, validation, intégrations et audit. | Aucune fonction d’administration ; instances interchangeables. |
| Stockage de session partagé | Conserver les sessions si l’architecture n’est pas totalement sans état. | Chiffré, hautement disponible, expiration obligatoire. |
| Base applicative dédiée | Conserver seulement les données non autoritaires nécessaires au portail. | Identifiants dédiés ; migrations versionnées ; sauvegardes chiffrées. |
| Stockage des photos | Conserver les images validées et leurs métadonnées. | Non exécutable, privé, sauvegardé, contrôlé et servi avec un type sûr. |
| GLPI | Source des tickets et interventions. | Compte technique minimal ; filtrage des commentaires internes. |
| Passerelle VM | Ouvrir une session vers la seule VM attribuée. | Aucun identifiant ni protocole d’administration exposé au navigateur. |
| Source d’état | Fournir l’état simplifié des services. | Lecture seule, appels bornés, cache et délai d’expiration. |
| Logs centralisés | Conserver et corréler les événements. | L’application ne doit pas pouvoir modifier les événements déjà livrés. |

### 5.3 Séparation avec le portail d’administration

Le portail salarié doit avoir ses propres :

- nom DNS et virtual host ;
- pool applicatif ;
- configuration Nginx ;
- comptes techniques ;
- identifiants de base de données ou schéma dédié ;
- secrets, clés de chiffrement et certificats ;
- cookies et préfixes de session ;
- journaux identifiables ;
- pipeline de déploiement ;
- règles réseau.

Le back-end salarié ne doit contenir ni route, ni contrôleur, ni permission, ni lien permettant d’administrer l’infrastructure. Le masquage d’un bouton dans le front-end n’est jamais considéré comme une mesure d’autorisation.

### 5.4 Cohérence avec l’infrastructure Site-B

Le [dossier réseau](../../Infrastructure/docs/Dossier_reseau.md) décrit actuellement :

- un load balancer Nginx en `172.16.3.72/26` ;
- trois backends Web en `172.16.3.80`, `.81` et `.82` ;
- un DNAT HTTPS depuis Internet vers le load balancer ;
- un flux interne du load balancer vers les backends en HTTP ;
- un accès HTTPS au load balancer depuis les VLAN 10 et 20 et depuis le poste d’administration.

Ces éléments ne peuvent pas être repris sans arbitrage :

- `SAL-NET-006` interdit l’exposition directe du portail salarié sur Internet ;
- le portail doit donc utiliser un listener, un virtual host et un DNS internes, sans DNAT public ;
- le VLAN 30 est candidat dans le CDC mais actuellement isolé des réseaux privés par la politique réseau ;
- le CDC impose HTTPS sur tous les parcours : la terminaison TLS et le chiffrement éventuel du segment load balancer/back-end doivent être validés explicitement ;
- les règles réseau finales doivent distinguer le trafic du portail salarié de tout autre site Web publié.

Le développeur ne doit pas modifier ces choix d’infrastructure de sa propre initiative. Il doit produire la liste précise des flux nécessaires afin que l’équipe réseau les valide.

## 6. Découpage logique du back-end

Le choix du langage et du framework reste à valider. Quelle que soit la technologie, l’application doit séparer clairement les responsabilités suivantes.

### 6.1 Module Identité et session

Responsabilités :

- démarrer et terminer le parcours OIDC ;
- valider signature, émetteur, audience, expiration, nonce et état des réponses d’authentification ;
- convertir l’identité externe en contexte utilisateur interne ;
- refuser un utilisateur absent, désactivé ou ne possédant aucun groupe autorisé ;
- créer, renouveler et supprimer la session applicative ;
- fournir l’identité courante aux autres modules sans leur donner accès aux jetons bruts ;
- invalider la session si l’identité n’est plus autorisée selon la stratégie de révocation retenue ;
- journaliser succès, échecs, ouvertures et fermetures de session.

Le back-end ne doit jamais demander, recevoir, journaliser ou stocker le mot de passe AD.

### 6.2 Module Autorisation

Responsabilités :

- mapper les groupes et attributs AD vers les rôles applicatifs validés ;
- calculer le périmètre d’agence ;
- appliquer une politique de refus par défaut ;
- centraliser les règles afin d’éviter des contrôles différents selon les routes ;
- évaluer les droits à chaque requête sensible ;
- contrôler la propriété de la ressource pour les VM et tickets ;
- produire une décision exploitable par l’audit : autorisé/refusé et motif normalisé.

Le contrôle doit combiner RBAC et règles contextuelles : le rôle ouvre une capacité générale, tandis que l’identité, l’agence, les groupes, l’affectation et la propriété limitent la ressource concrète.

### 6.3 Module Profil

Responsabilités :

- exposer en lecture seule nom, prénom, e-mail professionnel, agence, fonction/rôle et autres attributs validés issus de l’AD ;
- exposer séparément les préférences locales autorisées ;
- accepter uniquement la modification des champs explicitement placés sur liste positive ;
- gérer téléversement, remplacement et suppression éventuelle de la photo ;
- empêcher toute modification du rôle, de l’agence, du statut, des groupes ou des droits ;
- journaliser les changements de données locales.

### 6.4 Module Accueil et annonces

Responsabilités :

- récupérer les annonces publiées et non expirées ;
- filtrer les annonces par audience, agence et rôle ;
- agréger l’état des seuls services visibles par l’utilisateur ;
- traduire tout état externe vers `disponible`, `dégradé`, `indisponible` ou `maintenance` ;
- indiquer la fraîcheur de l’information ;
- fournir une réponse partielle utile si une source externe est indisponible.

La création ou l’administration des annonces ne fait pas partie du portail salarié. La source et son processus de publication doivent être définis avant d’implémenter ce module.

### 6.5 Module Catalogue de services

Responsabilités :

- conserver ou lire le catalogue validé ;
- filtrer par groupes, rôle, agence, droits explicites et période de disponibilité ;
- refuser par défaut un service sans règle d’autorisation ;
- exposer au front-end un libellé, une description, une catégorie, un état et une destination autorisée ;
- interdire les URL libres ou non validées afin d’éviter les redirections ouvertes ;
- rappeler que le service cible doit effectuer son propre contrôle d’accès.

### 6.6 Module Machine virtuelle

Responsabilités :

- lire l’affectation de VM depuis la source de référence ;
- retourner uniquement l’affectation de l’utilisateur courant ;
- ne jamais accepter un identifiant d’utilisateur fourni par le navigateur pour chercher une affectation ;
- vérifier que l’utilisateur est actif, autorisé au télétravail et que l’affectation est active ;
- demander à la passerelle un lancement limité dans le temps et lié à la VM autorisée ;
- ne jamais renvoyer d’adresse RDP/SSH directe, de mot de passe, de clé ou de secret de service ;
- journaliser la demande, la VM logique, le résultat et, si la passerelle le fournit, le début, la fin et la durée de connexion ;
- traiter la désactivation du salarié par révocation de session, d’affectation et d’accès distant.

Le presse-papiers, le transfert de fichiers, l’impression et la redirection de périphériques doivent être désactivés par défaut dans la solution de passerelle. Les exceptions doivent être explicites, limitées et auditées.

### 6.7 Module Tickets et demandes de droits

Responsabilités :

- créer un ticket avec identifiant unique dans GLPI ou dans l’outil validé ;
- imposer les champs obligatoires et les valeurs de listes contrôlées ;
- associer automatiquement le demandeur et l’agence depuis la session, sans faire confiance à ces valeurs si elles viennent du client ;
- permettre la consultation des seuls tickets du demandeur ;
- filtrer les commentaires internes des techniciens ;
- exposer l’historique publiable, le statut, la priorité, l’affectation visible, la clôture et son motif ;
- créer une demande de droit comme une catégorie spécifique de ticket ;
- ne jamais accorder le droit en réponse à la simple création du ticket ;
- garantir l’idempotence d’une création rejouée après une erreur réseau ;
- journaliser création, consultation sensible et changement visible.

Une demande de réinitialisation de mot de passe AD doit rester un ticket et une procédure humaine. Le back-end salarié ne doit fournir aucune opération de changement ou de reset du mot de passe AD.

### 6.8 Module Audit et observabilité

Responsabilités :

- créer ou propager un identifiant de corrélation pour chaque requête ;
- produire des événements structurés avec un schéma stable ;
- masquer jetons, cookies, mots de passe, secrets, données de session et informations inutiles ;
- envoyer les événements au collecteur central ;
- exposer métriques, état de santé et traces techniques sans données personnelles ;
- signaler l’indisponibilité ou la dérive des intégrations.

### 6.9 Module Connecteurs externes

Chaque connecteur doit :

- avoir une interface interne propre et ne pas contaminer le domaine avec le format du fournisseur ;
- utiliser un compte technique au moindre privilège ;
- appliquer des délais d’attente courts et configurables ;
- borner pagination, taille de réponse et nombre d’appels ;
- distinguer erreur fonctionnelle, indisponibilité, réponse invalide et refus d’autorisation ;
- utiliser des reprises limitées avec temporisation uniquement pour les opérations rejouables ;
- mettre en œuvre un coupe-circuit si nécessaire ;
- exposer la source, la date de dernière mise à jour et l’état d’erreur de toute donnée synchronisée ;
- ne jamais écrire de secret dans les journaux.

## 7. Identité, session et autorisation

### 7.1 Parcours SSO attendu

1. Une requête autorisée par le réseau arrive au portail.
2. En l’absence de session, le back-end démarre le flux OIDC Authorization Code ; PKCE doit être utilisé lorsque le type de client le justifie.
3. Le fournisseur d’identité tente l’authentification intégrée Kerberos/SPNEGO.
4. Après succès, le back-end valide strictement la réponse OIDC.
5. Il extrait uniquement les claims documentés et place l’identité dans une projection interne normalisée.
6. Il vérifie le statut de l’utilisateur et la présence d’au moins une habilitation d’accès au portail.
7. Il crée une session applicative et envoie un cookie sécurisé.
8. Il calcule les droits pour chaque requête à partir de données suffisamment fraîches.
9. En cas d’échec, il affiche une erreur compréhensible et un moyen de contacter l’assistance, sans créer de compte local de secours.

### 7.2 Claims minimaux à contractualiser

| Claim logique | Utilisation | Règle |
| --- | --- | --- |
| Identifiant immuable | Clé de rapprochement du salarié | Obligatoire ; ne pas utiliser l’e-mail comme clé. |
| Nom d’affichage | Présentation | Lecture seule depuis l’AD. |
| Prénom et nom | Profil | Lecture seule depuis l’AD. |
| E-mail professionnel | Profil et rapprochement GLPI si validé | Lecture seule ; non utilisé seul pour l’autorisation. |
| Groupes | Mapping des rôles et services | Liste filtrée aux groupes nécessaires. |
| Agence | Périmètre fonctionnel | Valeur contrôlée, issue d’un attribut ou mapping validé. |
| Rôle métier | Employé ou Direction | Calculé par mapping ; aucune élévation côté client. |
| Statut actif | Autorisation de session | Un statut inactif provoque un refus et la révocation selon la politique définie. |

Le contrat doit définir le comportement en cas de claim absent, multiple, inconnu ou contradictoire. Le comportement sûr par défaut est le refus.

### 7.3 Cookie et session

Le cookie de session doit être :

- `Secure` ;
- `HttpOnly` ;
- configuré avec un `SameSite` adapté au parcours OIDC ;
- limité au nom d’hôte et au chemin nécessaires ;
- dépourvu de donnée personnelle lisible ;
- différent de tout cookie du portail d’administration.

La session doit avoir une durée absolue et une durée d’inactivité configurables. Les identifiants de session doivent être renouvelés après authentification et lors d’un changement de niveau de confiance. Une déconnexion doit supprimer la session côté serveur, expirer le cookie et produire un événement d’audit. La stratégie de déconnexion du fournisseur d’identité doit être décidée séparément pour ne pas provoquer de comportement SSO inattendu.

### 7.4 Matrice d’autorisation du portail salarié

| Action | Employé | Direction | Condition supplémentaire |
| --- | :---: | :---: | --- |
| Consulter les annonces | Oui | Oui | Audience, agence et période compatibles. |
| Consulter l’état d’un service | Oui | Oui | Service autorisé à l’utilisateur. |
| Consulter son profil | Oui | Oui | Uniquement l’identité courante. |
| Modifier ses champs locaux autorisés | Oui | Oui | Liste positive de champs. |
| Modifier rôle, agence, statut ou droits | Non | Non | Toujours refusé côté serveur. |
| Consulter le catalogue | Oui | Oui | Résultat filtré par droits. |
| Consulter/lancer sa VM | Selon affectation | Selon affectation | Utilisateur actif, droit distant et affectation active. |
| Créer un ticket | Oui | Oui | Catégorie autorisée et données valides. |
| Consulter un ticket | Oui | Oui | Le salarié est le demandeur. |
| Voir un commentaire interne | Non | Non | Jamais renvoyé par l’API salarié. |
| Demander un droit | Oui | Oui | Création d’un ticket, sans attribution automatique. |
| Accéder à une fonction d’administration | Non | Non | Refus serveur, même par URL directe. |

Les éventuelles synthèses métier de la Direction doivent être absentes tant que leur contenu exact n’a pas été validé.

## 8. Contrat d’API attendu

Les chemins ci-dessous constituent un contrat fonctionnel recommandé. L’agent développeur peut ajuster la convention de nommage, mais doit préserver les responsabilités, les contrôles et les résultats attendus. Toutes les routes métier sont versionnées et nécessitent une session valide, sauf les contrôles de santé internes et les points d’entrée techniques du parcours OIDC.

### 8.1 Session

| Opération | Finalité | Contrôles essentiels | Audit |
| --- | --- | --- | --- |
| Démarrer la connexion | Initier OIDC si aucune session n’existe. | `state`, `nonce`, URI de retour sur liste positive, anti-redirection ouverte. | Tentative et résultat d’authentification. |
| Traiter le retour OIDC | Créer la session après validation. | Signature, émetteur, audience, code, nonce, expiration, claims requis, utilisateur actif. | Succès ou échec avec motif non sensible. |
| Lire la session courante | Fournir identité d’affichage, rôle et capacités utiles au front. | Ne renvoyer ni jeton brut ni groupes inutiles. | Facultatif sauf accès sensible. |
| Se déconnecter | Invalider la session applicative. | Révocation côté serveur et expiration du cookie. | Fermeture de session. |

### 8.2 Accueil et services

| Opération | Résultat attendu | Règles |
| --- | --- | --- |
| Lire l’accueil | Annonces ciblées, services autorisés et état synthétique. | Ne jamais inclure un service non autorisé ; indiquer la fraîcheur et les erreurs partielles. |
| Lister les annonces | Annonces actives correspondant à l’audience. | Pagination bornée ; dates cohérentes ; contenu assaini. |
| Lister les services | Catalogue filtré. | Filtrage côté serveur par rôle, groupe, agence et affectation. |
| Lire un service | Détail d’un service déjà autorisé. | Refuser l’accès direct à un identifiant non autorisé. |

### 8.3 Profil

| Opération | Résultat attendu | Règles |
| --- | --- | --- |
| Lire mon profil | Attributs AD en lecture seule et préférences locales. | Aucun paramètre permettant de choisir un autre utilisateur. |
| Modifier mes préférences | Mise à jour des seuls champs locaux autorisés. | Liste positive ; ignorer n’est pas suffisant : refuser les champs interdits. |
| Téléverser/remplacer ma photo | Photo validée et métadonnées mises à jour. | Contrôles serveur, analyse du contenu, stockage privé, audit. |
| Supprimer ma photo | Retour à l’image par défaut si cette fonction est validée. | L’utilisateur ne peut supprimer que sa propre photo. |

### 8.4 Machine virtuelle

| Opération | Résultat attendu | Règles |
| --- | --- | --- |
| Lire mon affectation | VM logique, état utile et disponibilité du bouton de connexion. | Aucune recherche par identifiant salarié arbitraire. |
| Demander une connexion | URL ou jeton de lancement éphémère vers la passerelle. | Revalider l’affectation ; TTL court ; usage limité ; aucun secret durable. |
| Lire l’état d’une demande de lancement | Résultat maîtrisé du lancement si nécessaire. | L’utilisateur doit posséder la demande et l’affectation. |

La destination réelle, les identifiants techniques et les paramètres de protocole restent exclusivement côté serveur et côté passerelle.

### 8.5 Tickets

| Opération | Résultat attendu | Règles |
| --- | --- | --- |
| Créer un ticket | Identifiant externe, date et statut initial. | Demandeur/agence issus de la session ; idempotence ; catégorie et priorité contrôlées. |
| Lister mes tickets | Liste paginée et filtrable des tickets du demandeur. | Filtres bornés ; aucun ticket d’un tiers. |
| Lire mon ticket | Détail et historique publiable. | Vérifier la propriété avant d’appeler ou d’exposer la ressource. |
| Ajouter une information | Commentaire salarié ou pièce jointe si cette fonction est validée. | Propriété, statut compatible, validation et antivirus des pièces jointes. |
| Créer une demande de droit | Ticket catégorisé et motivé. | Aucun changement d’habilitation ; validation administrative ultérieure. |

Les pièces jointes ne doivent pas être implémentées tant que formats, taille, antivirus, stockage, durée de conservation et règles GLPI ne sont pas validés.

### 8.6 Santé et exploitation

| Contrôle | Usage | Contenu autorisé |
| --- | --- | --- |
| Vivacité | Savoir si le processus répond. | État binaire, version technique non sensible si nécessaire. |
| Disponibilité | Décider si l’instance peut recevoir du trafic. | État des dépendances indispensables, sans URL, secret ni détail d’infrastructure. |
| Métriques | Supervision et capacité. | Compteurs et durées agrégés ; aucune donnée personnelle ou identifiant de session. |

Ces routes doivent être limitées aux composants de supervision et au load balancer. Elles ne doivent pas devenir une source d’inventaire pour un utilisateur du portail.

## 9. Modèle de données et sources de référence

### 9.1 Principes

- Ne pas recopier une donnée autoritaire sans nécessité démontrée.
- Toute projection ou cache doit porter sa source, sa date de mise à jour et son état de synchronisation.
- Utiliser un identifiant technique immuable pour les relations ; ne pas lier durablement les données à l’adresse e-mail.
- Prévoir contraintes d’unicité, clés étrangères, dates en UTC et migrations versionnées.
- Définir une politique de suppression ou d’anonymisation pour chaque catégorie de données.
- Séparer les données opérationnelles des événements d’audit.

### 9.2 Entités minimales à prévoir

| Entité logique | Données principales | Source de référence | Persistance locale |
| --- | --- | --- | --- |
| Projection salarié | Identifiant immuable, identité, e-mail, agence, rôle, statut, groupes utiles, fraîcheur. | Active Directory via le fournisseur d’identité. | Cache/projection uniquement si nécessaire. |
| Préférences de profil | Champs personnels explicitement modifiables. | Portail salarié. | Oui. |
| Photo de profil | Propriétaire, clé objet, type détecté, dimensions, taille, empreinte, dates, état d’analyse. | Portail salarié. | Métadonnées en base, fichier en stockage privé. |
| Annonce | Identifiant source, titre, contenu assaini, audience, agences/rôles, publication, expiration, état. | Source de publication à définir. | Projection/cache selon la solution. |
| Service | Identifiant, libellé, description, catégorie, destination validée, état, règles de visibilité. | Catalogue validé à définir. | Oui ou projection contrôlée. |
| Affectation VM | Salarié, VM logique, droit distant, état, début/fin, dernière synchronisation. | Outil de virtualisation/VDI ou référentiel validé. | Projection seulement. |
| Demande de lancement VM | Salarié, affectation, horodatage, expiration, résultat, identifiant passerelle. | Portail et passerelle. | Oui, durée courte selon audit. |
| Mapping externe | Identifiant salarié vers identifiant GLPI/passerelle. | Intégrations validées. | Oui, sans secret. |
| Ticket | Identifiant, demandeur, agence, catégorie, priorité, statut, technicien visible, dates, clôture. | GLPI si retenu. | Pas de duplication complète ; cache borné éventuel. |
| Historique publiable | Action, auteur affichable, date, contenu visible. | GLPI. | Projection filtrée éventuelle. |
| Événement d’audit | Corrélation, acteur, source IP, action, ressource, résultat, motif, date. | Portail puis plateforme de logs. | File/outbox technique temporaire si nécessaire. |

### 9.3 Données interdites dans la base applicative

- mot de passe AD ;
- secret ou clé de compte salarié ;
- code MFA ;
- jeton OIDC durable en clair ;
- cookie ou identifiant de session dans les journaux ;
- mot de passe RDP/SSH ;
- clé privée de certificat ;
- secret de compte technique ;
- copie complète de commentaires GLPI internes ;
- groupes AD sans utilité pour l’autorisation du portail.

## 10. Règles métier détaillées

### 10.1 Accueil

- Afficher uniquement les annonces actives au moment de la requête.
- Une annonce sans audience valide ne doit pas être publiée par défaut.
- L’état d’un service doit être normalisé dans les quatre états du CDC.
- Un état trop ancien doit être présenté comme inconnu/indisponible selon la décision UX, jamais comme disponible par défaut.
- L’indisponibilité d’une source ne doit pas dévoiler son adresse, son nom technique ou une trace d’erreur.
- Une réponse partielle doit préciser quelles informations n’ont pas pu être actualisées.

### 10.2 Profil et photo

- Les champs AD sont en lecture seule, y compris si le client envoie une valeur différente.
- Les champs non prévus sont refusés explicitement.
- Le type d’image doit être déterminé par inspection du contenu, pas par l’extension ou le type déclaré par le navigateur.
- Les formats, dimensions et poids doivent respecter la liste positive validée.
- Le fichier doit être réencodé ou traité de façon à éliminer les contenus actifs et métadonnées inutiles.
- Le nom d’origine ne doit pas devenir un chemin de stockage.
- Le stockage ne doit pas autoriser l’exécution de fichiers.
- L’ancienne image doit être supprimée ou conservée selon une politique documentée et testée.
- Toute image refusée doit produire une erreur utilisateur claire et un événement technique sans contenu sensible.

### 10.3 Services

- Une autorisation d’affichage ne vaut pas autorisation dans le service cible.
- Toute destination doit appartenir à une liste gérée et validée.
- Les règles de visibilité doivent pouvoir cibler un rôle, un groupe, une agence ou une affectation explicite.
- En cas de conflit entre une permission et une interdiction, l’interdiction l’emporte.
- Les services expirés, désactivés ou non configurés ne sont pas proposés.

### 10.4 VM et télétravail

- Une seule identité courante sert à chercher l’affectation.
- Une tentative d’accès à l’identifiant d’une autre VM est refusée et auditée.
- Le lancement doit utiliser une intention éphémère, à usage unique si la passerelle le permet.
- Le back-end doit revalider l’affectation immédiatement avant le lancement.
- Une VM arrêtée ou une passerelle indisponible produit un état maîtrisé, sans proposer de contournement direct.
- La désactivation d’un salarié doit rendre inutilisable toute session de portail et tout lancement encore actif, selon les capacités de la passerelle.
- Les événements de connexion doivent permettre de retrouver utilisateur, VM logique, début, fin, durée et résultat.

### 10.5 Tickets

- Le demandeur et l’agence viennent du contexte authentifié.
- La description est obligatoire, bornée et traitée comme du contenu non fiable.
- Catégorie, priorité et statut utilisent des valeurs contrôlées mappées avec GLPI.
- Un salarié ne peut ni choisir un technicien arbitraire ni marquer lui-même une demande de droit comme approuvée.
- Les commentaires internes sont retirés côté connecteur ou domaine avant sérialisation.
- La liste et le détail appliquent tous deux le contrôle de propriété.
- Une ressource appartenant à un autre utilisateur doit être présentée comme introuvable ou inaccessible selon la convention validée, puis auditée.
- La fermeture et son motif sont visibles seulement si GLPI les déclare publiables.

### 10.6 Demandes de droits et mot de passe

- Une demande de droit contient le service ou droit demandé, la justification, la durée souhaitée si temporaire et les informations de contexte autorisées.
- Sa création n’appelle aucune API d’attribution de droits.
- L’approbation est réalisée dans le portail d’administration ou l’outil de référence par une personne autorisée.
- Le résultat final doit être rapproché du ticket et contrôlé avant clôture.
- Une demande de réinitialisation de mot de passe suit le processus humain décrit dans le CDC ; aucun endpoint salarié ne change le mot de passe AD.
- Si une page non authentifiée est retenue, elle constitue un mini-produit séparé : réseau limité, anti-abus, message non énumérable, journalisation, aucune fonction de reset et revue de sécurité dédiée.

## 11. Intégrations à spécifier

### 11.1 Active Directory et fournisseur d’identité

Livrables attendus avant codage :

- schéma du flux Kerberos/SPNEGO puis OIDC ;
- realm/tenant et client dédiés au portail salarié ;
- URI de redirection exactes par environnement ;
- liste des claims et exemples anonymisés ;
- mapping groupes/rôles/agences ;
- stratégie de synchronisation et de désactivation ;
- politique de clés de signature et rotation ;
- comportement en cas d’indisponibilité ;
- comptes techniques et permissions minimales.

### 11.2 GLPI

Livrables attendus :

- version et documentation d’API ;
- environnement de test ;
- méthode d’authentification du compte technique ;
- périmètre exact de lecture/écriture ;
- mapping des identités ;
- mapping catégories, priorités et statuts ;
- définition d’un commentaire public/interne ;
- règles de pagination et limites ;
- stratégie d’idempotence ;
- jeux de réponses anonymisées, erreurs comprises ;
- procédure de révocation et rotation des secrets.

### 11.3 Passerelle VM

Livrables attendus :

- solution choisie et architecture ;
- source des affectations ;
- API ou protocole de lancement ;
- durée et portée des jetons éphémères ;
- mécanisme empêchant la substitution de VM ;
- options de session désactivées par défaut ;
- événements de début, fin et résultat ;
- comportement en cas de révocation ;
- compte technique et permissions ;
- procédure de test sans exposer RDP/SSH.

### 11.4 État des services et annonces

Livrables attendus :

- source de chaque information ;
- propriétaire métier ;
- modèle d’audience ;
- fréquence de rafraîchissement ;
- durée maximale du cache ;
- mapping vers les quatre états affichables ;
- comportement en cas de données anciennes ou absentes ;
- limites d’appel et mécanisme de reprise.

## 12. Sécurité applicative

### 12.1 Entrées et sorties

- Valider toutes les entrées côté serveur avec types, bornes, formats et listes positives.
- Utiliser des requêtes paramétrées ou un ORM correctement configuré.
- Encoder les sorties selon leur contexte et assainir les contenus riches autorisés.
- Protéger les requêtes modifiant l’état contre le CSRF lorsque l’authentification repose sur un cookie.
- Limiter la taille globale des requêtes, champs, listes et fichiers.
- Refuser les traversées de chemin et noms de fichier dangereux.
- Configurer des en-têtes de sécurité : CSP adaptée, `X-Content-Type-Options`, `Referrer-Policy` et autres en-têtes validés.
- Activer HSTS seulement après validation complète de HTTPS dans les environnements concernés.

### 12.2 Adresse IP source et proxies

- Le client ne doit jamais pouvoir choisir l’adresse source utilisée pour les décisions ou l’audit.
- Le premier proxy de confiance doit écraser les en-têtes entrants tels que `X-Forwarded-For` et `X-Real-IP`.
- L’application ne doit accepter ces en-têtes que lorsque la connexion immédiate provient d’un proxy explicitement approuvé.
- La chaîne complète doit être testée avec des en-têtes forgés.
- Le refus CIDR principal doit intervenir dans Nginx avant le SSO et avant l’application.
- Les refus Nginx doivent être transmis au stockage central afin de satisfaire l’audit sans solliciter le back-end.

### 12.3 Gestion des secrets

- Aucun secret réel dans Git, les images, les fichiers d’exemple ou les journaux.
- Injection par gestionnaire de secrets ou mécanisme équivalent approuvé.
- Secret différent par service et environnement.
- Permissions minimales et durée de vie limitée lorsque possible.
- Procédure de rotation testée sans interruption excessive.
- Inventaire du propriétaire, de l’usage et de la date de rotation de chaque secret.

### 12.4 Limitation et anti-abus

- Limiter les parcours d’authentification, téléversements, créations de ticket et lancements VM.
- Appliquer les limites par combinaison pertinente : IP fiable, session et identité.
- Ne pas utiliser une limite globale qui permettrait à un utilisateur de bloquer tous les autres.
- Renvoyer une erreur maîtrisée et journaliser les dépassements significatifs.
- Définir des quotas et délais cohérents avec le nombre d’utilisateurs validé.

### 12.5 Dépendances

- Verrouiller les versions de dépendances et conserver un inventaire logiciel.
- Analyser les vulnérabilités dans le pipeline.
- Définir une procédure de mise à jour régulière et urgente.
- Refuser une mise en production avec une vulnérabilité critique non acceptée formellement.
- Générer un SBOM si l’outillage retenu le permet.

## 13. Journalisation et protection des données

### 13.1 Schéma minimal d’un événement

Chaque événement d’audit doit porter :

- date et heure synchronisées en UTC ;
- identifiant de corrélation ;
- type et version de l’événement ;
- identifiant pseudonymisé ou technique de l’acteur ;
- compte de service lorsque pertinent ;
- adresse IP source retenue selon la chaîne de confiance ;
- action ;
- type et identifiant logique de la ressource ;
- résultat ;
- motif normalisé si nécessaire ;
- environnement et instance émettrice.

### 13.2 Événements obligatoires pour ce portail

- succès et échec d’authentification ;
- ouverture, renouvellement significatif et fermeture de session ;
- utilisateur AD non autorisé ou désactivé ;
- refus d’autorisation, notamment accès à la VM ou au ticket d’un tiers ;
- consultation/export de données considérées sensibles ;
- modification de profil ou de photo ;
- création de ticket ou de demande de droit ;
- demande et résultat d’un lancement VM ;
- erreur significative d’intégration ;
- changement d’état de santé d’une dépendance ;
- refus CIDR émis par Nginx.

### 13.3 Éléments à ne jamais journaliser

- mot de passe ;
- jeton OIDC, code d’autorisation ou cookie ;
- secret de service ;
- contenu binaire d’une photo ou pièce jointe ;
- URL de lancement VM contenant un jeton ;
- en-têtes complets non filtrés ;
- corps complet d’une requête par défaut ;
- commentaire GLPI interne ;
- données personnelles sans nécessité d’audit.

### 13.4 Vie privée

- Définir la finalité de chaque donnée collectée.
- Informer les salariés du traitement et de la journalisation.
- Appliquer une durée de conservation par catégorie.
- Restreindre l’accès aux photos, profils et historiques.
- Permettre la rectification des données locales ; les données AD doivent être corrigées dans l’AD.
- Documenter départ, désactivation, révocation et suppression/anonymisation.
- Faire valider le traitement par le référent compétent avant production.

## 14. Résilience, performance et exploitation

### 14.1 Résilience

- Les instances applicatives doivent être interchangeables.
- Une session ne doit pas dépendre d’un fichier local à une instance.
- Le load balancer doit retirer une instance non prête.
- Les appels externes doivent avoir un délai d’attente et ne pas bloquer indéfiniment une requête.
- Les données non critiques peuvent utiliser un cache partagé avec expiration.
- Une panne de la source d’annonces ne doit pas empêcher l’accès au profil ou aux tickets.
- Une panne GLPI doit empêcher proprement les opérations de ticket sans dégrader les autres modules.
- Une panne de la passerelle VM doit afficher l’indisponibilité sans révéler de solution directe.
- Les opérations d’écriture rejouables doivent être idempotentes.

### 14.2 Performance

- Viser un affichage courant en moins de deux secondes au 95e percentile sur le réseau interne.
- Paginer côté serveur toutes les listes potentiellement non bornées.
- Interdire les appels d’API externes non bornés.
- Mettre en cache seulement les données compatibles avec leur exigence de fraîcheur.
- Mesurer séparément temps applicatif, base, fournisseur d’identité, GLPI, état des services et passerelle VM.
- Tester le nombre d’utilisateurs simultanés validé, plus une marge convenue.
- Le `403` réseau doit rester traité par Nginx sans appel applicatif.

### 14.3 Sauvegarde et restauration

La stratégie doit couvrir :

- base applicative ;
- stockage des photos ;
- configuration non secrète ;
- secrets sous forme chiffrée et restaurable par le processus approuvé ;
- mappings d’intégration ;
- documentation d’exploitation ;
- version des migrations et artefacts déployés.

Une restauration complète doit être testée dans un environnement isolé. Le procès-verbal doit indiquer sauvegarde utilisée, étapes, durée, écarts, contrôle d’intégrité et validation fonctionnelle.

### 14.4 Configuration par environnement

Prévoir au minimum développement, recette et production, avec :

- fournisseurs d’identité ou clients distincts ;
- bases et secrets distincts ;
- destinations d’intégration distinctes ;
- noms DNS et certificats propres ;
- niveaux de logs appropriés ;
- aucune donnée personnelle de production copiée en développement ;
- fonctions de diagnostic désactivées en production.

## 15. Gestion des erreurs

Le contrat d’erreur doit être stable, documenté et exploitable par le front-end. Il doit contenir un code fonctionnel, un message utilisateur en français, l’identifiant de corrélation et éventuellement des erreurs de champs. Il ne doit pas contenir de trace, requête SQL, nom de serveur, secret ou détail d’intégration.

Cas minimaux à prévoir :

| Situation | Comportement attendu |
| --- | --- |
| Source réseau interdite | `403` par Nginx, sans SSO ni appel back-end. |
| Session absente/expirée | Reprise contrôlée du parcours de connexion ou erreur d’authentification convenue. |
| Utilisateur AD non autorisé | Refus, message d’assistance et audit. |
| Ressource d’un autre salarié | Refus côté serveur, réponse non révélatrice et audit. |
| Entrée invalide | Erreur de validation localisée par champ. |
| Source externe indisponible | Réponse dégradée ou erreur fonctionnelle spécifique, avec corrélation. |
| Création de ticket incertaine | Vérifier l’idempotence avant nouvelle création. |
| VM sans affectation | État explicite, aucun bouton de connexion. |
| Photo refusée | Motif utilisateur compréhensible sans détail dangereux. |
| Erreur inattendue | Message générique, corrélation et log technique filtré. |

## 16. Stratégie de tests

### 16.1 Tests unitaires

- mapping des claims vers les rôles et agences ;
- refus en cas de claim manquant ou contradictoire ;
- règles d’autorisation par rôle, agence, propriété et affectation ;
- filtrage du catalogue ;
- normalisation des états de service ;
- validation des champs et fichiers ;
- masquage des commentaires internes ;
- conversion des erreurs externes ;
- génération du schéma d’audit sans secret.

### 16.2 Tests d’intégration

- parcours OIDC avec fournisseur d’identité de recette ;
- renouvellement et déconnexion de session ;
- base et migrations depuis une base vide puis depuis la version précédente ;
- GLPI : création idempotente, liste filtrée, détail, pagination et erreurs ;
- passerelle VM : affectation valide, absence, révocation, expiration et panne ;
- stockage photo : type réel, taille, dimensions, remplacement et suppression ;
- envoi des logs et comportement si le collecteur est temporairement indisponible.

### 16.3 Tests d’autorisation obligatoires

Pour chaque route métier, tester au minimum :

1. utilisateur autorisé ;
2. utilisateur authentifié mais sans rôle requis ;
3. utilisateur d’une autre agence lorsque le périmètre intervient ;
4. tentative d’accès à la ressource d’un autre salarié ;
5. identifiant inexistant ;
6. session expirée ;
7. appel direct sans passer par l’écran attendu ;
8. paramètres ou champs supplémentaires visant une élévation de privilèges.

### 16.4 Tests réseau et proxy

- réseau salarié autorisé : accès HTTPS et SSO ;
- réseau non autorisé : `403` sans redirection ;
- Internet : aucun accès au portail ;
- en-têtes `X-Forwarded-For` et `X-Real-IP` forgés : aucun contournement ;
- accès direct à une instance applicative : impossible depuis un réseau client ;
- perte d’une instance : retrait du pool sans perte anormale de session ;
- contrôle de santé : aucune donnée sensible.

### 16.5 Tests sécurité

- injection SQL et commande ;
- XSS stockée et réfléchie ;
- CSRF sur chaque écriture ;
- traversée de chemin ;
- téléversements polyglottes, trop volumineux, malformés ou à type trompeur ;
- redirection ouverte ;
- falsification de jeton OIDC et validation incorrecte d’audience/émetteur ;
- fixation, vol simulé et réutilisation de session ;
- contrôle de débit ;
- fuite de secrets dans réponses et logs ;
- appels directs à des routes d’administration inexistantes ou interdites ;
- tentative d’accès à une VM ou un ticket d’un autre utilisateur.

### 16.6 Tests de performance et résilience

- charge nominale et pic validés ;
- mesure du 95e percentile ;
- latence et panne de chaque intégration ;
- cache expiré ou indisponible ;
- coupure puis reprise de la base ;
- coupure du stockage de session ;
- reprise après redéploiement ;
- restauration d’une sauvegarde ;
- absence de doublon après rejeu d’une création de ticket.

## 17. Traçabilité vers les exigences du CDC

| Exigence | Travail d’implémentation | Preuve attendue |
| --- | --- | --- |
| SAL-NET-001 | Liste positive des réseaux internes/VPN validés. | Matrice de flux et test depuis chaque réseau. |
| SAL-NET-002 | Filtrage CIDR dans le Nginx salarié. | Revue de configuration et tests autorisé/refusé. |
| SAL-NET-003 | Refus 403 avant authentification. | Capture de test prouvant l’absence de redirection SSO. |
| SAL-NET-004 | ACL et pare-feu cohérents avec Nginx. | Configuration validée et procès-verbal réseau. |
| SAL-NET-005 | Chaîne de proxies de confiance et écrasement des en-têtes. | Tests d’en-têtes forgés. |
| SAL-NET-006 | Aucun DNS/DNAT public pour ce portail. | Test externe et revue des règles. |
| SAL-AUTH-001 | SSO transparent sur poste joint au domaine. | Test utilisateur de recette. |
| SAL-AUTH-002 | Kerberos/SPNEGO côté IdP et OIDC côté application. | Schéma, configuration et traces de recette filtrées. |
| SAL-AUTH-003 | Mapping groupes AD vers rôles/capacités. | Matrice de mapping et tests automatisés. |
| SAL-AUTH-004 | Aucun mot de passe AD dans l’application. | Revue de code, schéma de données et scan de logs. |
| SAL-AUTH-005 | Erreur claire sans compte local de secours. | Test d’échec SSO et contenu affiché. |
| SAL-AUTH-006 | Session configurable et déconnexion effective. | Tests expiration, renouvellement et logout. |
| SAL-FONC-001 | Source et filtrage des annonces. | Tests d’audience et d’expiration. |
| SAL-FONC-002 | Agrégation de l’état des services. | Tests des quatre états et panne de source. |
| SAL-FONC-003 | Catalogue filtré par rôle/agence/droits. | Tests positifs et négatifs. |
| SAL-FONC-004 | États normalisés et compréhensibles. | Contrat d’API et validation UX. |
| SAL-PRO-001 | Attributs AD exposés en lecture seule. | Tentatives de modification refusées. |
| SAL-PRO-002 | Mise à jour limitée aux données locales validées. | Tests de liste positive. |
| SAL-PRO-003 | Rôle, agence, statut et droits non modifiables. | Tests d’élévation et appel direct. |
| SAL-PRO-004 | Validation serveur des photos. | Batterie de fichiers valides et malveillants. |
| SAL-VM-001 | Référentiel d’affectation personnel/pool. | Test d’un utilisateur affecté et non affecté. |
| SAL-VM-002 | Accès extérieur préalable via VPN/passerelle MFA. | Recette d’accès distant, hors back-end seul. |
| SAL-VM-003 | Résolution de la seule VM attribuée. | Test croisé entre deux salariés. |
| SAL-VM-004 | Aucun RDP/SSH publié. | Scan réseau externe et revue pare-feu. |
| SAL-VM-005 | Lancement via passerelle validée. | Démonstration de bout en bout. |
| SAL-VM-006 | Fonctions de redirection désactivées par défaut. | Revue de la politique de passerelle. |
| SAL-VM-007 | Journal des connexions et résultats. | Événements corrélés de test. |
| SAL-VM-008 | Révocation à la désactivation. | Test de désactivation et sessions existantes. |
| SAL-TIC-001 | Création de ticket. | Ticket GLPI avec champs obligatoires. |
| SAL-TIC-002 | Liste/détail des seuls tickets propres. | Test croisé entre deux demandeurs. |
| SAL-TIC-003 | Demande de droit sans ouverture automatique. | Test du workflow et preuve d’absence d’attribution. |
| SAL-TIC-004 | Historique complet des interventions dans la source. | Rapprochement ticket/audit. |
| SAL-TIC-005 | Commentaires internes non exposés. | Jeu de ticket mixte public/interne. |

## 18. Lots de réalisation

### Lot 0 — Validation et contrats

- [ ] Faire valider le CDC et la matrice des droits.
- [ ] Résoudre les décisions bloquantes de la section 4.
- [ ] Produire le schéma d’architecture et la liste des flux.
- [ ] Valider les maquettes et les états d’erreur.
- [ ] Contractualiser claims OIDC et APIs externes.
- [ ] Définir les critères de recette et jeux de données anonymisés.

**Sortie du lot :** dossier de décisions signé et aucune ambiguïté de sécurité empêchant le codage.

### Lot 1 — Socle applicatif

- [ ] Choisir le langage, le framework et les versions maintenues.
- [ ] Définir structure de modules, conventions et stratégie de configuration.
- [ ] Mettre en place base, migrations, session partagée et gestion des secrets.
- [ ] Définir erreurs, corrélation, logs, métriques et contrôles de santé.
- [ ] Mettre en place pipeline de qualité, tests, analyse de dépendances et artefacts.

**Sortie du lot :** application vide déployable, observable et testée, sans fonctionnalité métier.

### Lot 2 — Réseau, proxy et SSO

- [ ] Créer le virtual host interne du portail salarié.
- [ ] Appliquer TLS, CIDR autorisés, en-têtes sûrs et limitation de débit.
- [ ] Empêcher l’accès direct aux instances.
- [ ] Intégrer OIDC et la session applicative.
- [ ] Mapper identité, rôle et agence.
- [ ] Implémenter déconnexion et erreurs SSO.
- [ ] Tester les en-têtes de proxy forgés et les sources refusées.

**Sortie du lot :** un salarié autorisé ouvre et ferme une session ; toute source ou identité non autorisée est refusée et auditée.

### Lot 3 — Profil et autorisation

- [ ] Centraliser les politiques d’autorisation.
- [ ] Exposer le profil en lecture seule.
- [ ] Implémenter les préférences locales validées.
- [ ] Implémenter le pipeline sécurisé de photo.
- [ ] Tester toutes les tentatives de modification de rôle/agence/droits.

**Sortie du lot :** profil fonctionnel et aucune élévation par modification de requête.

### Lot 4 — Accueil et services

- [ ] Intégrer la source d’annonces.
- [ ] Intégrer la source d’état.
- [ ] Implémenter catalogue et règles de visibilité.
- [ ] Gérer cache, fraîcheur et réponses partielles.
- [ ] Tester les audiences Employé/Direction/agence/groupes.

**Sortie du lot :** l’accueil ne montre que des informations autorisées et reste exploitable en cas de panne partielle.

### Lot 5 — VM et télétravail

- [ ] Intégrer la source des affectations.
- [ ] Implémenter la consultation de l’affectation courante.
- [ ] Intégrer la création d’une intention de lancement éphémère.
- [ ] Corréler les événements portail/passerelle.
- [ ] Tester substitution, expiration, révocation et panne.

**Sortie du lot :** un salarié peut ouvrir uniquement sa VM via la passerelle, sans exposition de protocole ou de secret.

### Lot 6 — Tickets et demandes

- [ ] Implémenter le connecteur GLPI.
- [ ] Créer un ticket de façon idempotente.
- [ ] Lister et lire uniquement les tickets du demandeur.
- [ ] Filtrer les commentaires internes.
- [ ] Implémenter la catégorie de demande de droit.
- [ ] Tester pagination, propriété, erreurs et indisponibilité GLPI.

**Sortie du lot :** parcours complet de création et suivi, avec GLPI comme source unique et sans fuite inter-utilisateurs.

### Lot 7 — Durcissement et recette

- [ ] Exécuter les tests de sécurité et corriger les écarts.
- [ ] Réaliser tests de charge, panne et bascule.
- [ ] Vérifier l’absence de secrets dans dépôts, artefacts et logs.
- [ ] Tester sauvegarde et restauration.
- [ ] Exécuter la matrice de recette du CDC.
- [ ] Produire procès-verbal, dossier de sécurité, documentation d’exploitation et retour arrière.

**Sortie du lot :** toutes les exigences critiques disposent d’une preuve ; les écarts restants sont acceptés formellement ou corrigés.

## 19. Ordre de dépendance recommandé

1. Valider le réseau, l’identité, les rôles et les sources de données.
2. Construire le socle transversal : configuration, base, session, erreurs, audit, santé.
3. Sécuriser le chemin réseau et le SSO.
4. Implémenter le moteur d’autorisation avant les fonctions métier.
5. Livrer le profil, qui valide l’identité et les règles de modification.
6. Livrer accueil et services.
7. Intégrer VM et GLPI en parallèle seulement lorsque leurs contrats sont stables.
8. Effectuer durcissement, charge, restauration et recette complète.
9. Déployer en production avec supervision et plan de retour arrière.

Aucun lot métier ne doit contourner ou réimplémenter localement l’identité, l’autorisation, l’audit ou la gestion des erreurs.

## 20. Livrables attendus de l’agent développeur

- code source du back-end salarié ;
- migrations de base ;
- description du contrat d’API ;
- exemples de configuration sans secret ;
- configuration de référence du client OIDC ;
- contrats et adaptateurs GLPI, passerelle VM, annonces et état des services ;
- jeux de tests automatisés ;
- rapport de couverture des règles d’autorisation ;
- configuration Nginx salarié soumise à validation infrastructure ;
- matrice des flux réseau ;
- tableau de traçabilité exigences/tests ;
- documentation d’installation, exploitation et dépannage ;
- procédure de rotation des secrets ;
- procédure de sauvegarde/restauration testée ;
- procédure de révocation lors du départ d’un salarié ;
- rapport de sécurité et dépendances ;
- procès-verbal de recette ;
- plan de déploiement et de retour arrière.

## 21. Définition de « terminé »

Une fonctionnalité n’est terminée que si :

- son exigence et ses règles métier sont identifiées ;
- son contrat d’entrée/sortie est documenté ;
- ses autorisations sont appliquées côté serveur ;
- les cas de refus sont testés autant que le cas nominal ;
- ses données ont une source de référence et une durée de conservation ;
- ses événements d’audit sont définis et ne contiennent aucun secret ;
- ses erreurs sont compréhensibles et non sensibles ;
- ses dépendances externes ont délais d’attente, limites et comportement de panne ;
- ses tests unitaires et d’intégration passent ;
- ses exigences de sécurité passent ;
- la documentation d’exploitation est mise à jour ;
- une preuve de recette est rattachée à l’exigence du CDC ;
- aucun écart critique ou élevé ne reste ouvert sans acceptation formelle.

Le portail complet n’est prêt pour la production que si, en plus :

- il n’est pas accessible directement depuis Internet ;
- une source hors liste reçoit un `403` avant le SSO ;
- le SSO fonctionne sur un poste joint au domaine ;
- aucun compte salarié local de secours n’existe ;
- un salarié ne peut consulter ni VM ni ticket d’un autre salarié ;
- aucun menu ou endpoint d’administration n’est disponible ;
- RDP et SSH ne sont pas publiés ;
- les sauvegardes sont restaurées avec succès dans un environnement isolé ;
- les journaux permettent de corréler authentification, ticket et accès VM ;
- les validations métier, infrastructure et sécurité sont formalisées.

## 22. Consigne finale à l’agent qui codera

Avant de créer le premier composant métier, relire le [CDC complet](../CDC/CDC_yanis.md), les décisions validées et le [dossier réseau Site-B](../../Infrastructure/docs/Dossier_reseau.md). Ne pas remplacer un point encore ouvert par une hypothèse silencieuse. Toute hypothèse temporaire doit être visible, configurable, testée, associée à un propriétaire et interdite de production tant qu’elle n’est pas validée.

La priorité absolue est la suivante : **refuser par défaut, ne jamais faire confiance au client pour l’identité ou le périmètre, et ne jamais transformer le portail salarié en chemin d’administration de l’infrastructure.**
