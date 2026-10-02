# Ordre de déploiement DMZ - Site B

Référence : [schéma v1.1](../../docs/SITE_B_Schema.pdf) et
[paramètres des services](../Services.md).

| Étape | Action | Dépendance / contrôle |
| --- | --- | --- |
| 0 | Sauvegardes, console, pont Proxmox DMZ vers FW1 e0/1 | IP hyperviseur réservée hors pool, /26, GW .65 |
| 1 | FW1 .65/26, transits /30 et routes R1/FW1/SW1 | Voisins et retours joignables |
| 2 | Bind 172.16.3.71/26 | Récursion limitée, résolveurs approuvés |
| 3 | Serveur Web interne .70 et Web1 .80 | DNS .71, GW .65 ; dépôts HTTPS ou exception validée |
| 4 | Web2 .81 et Web3 .82 | IP uniques, /26, GW .65 |
| 5 | Ansible sur .80-.82 | SSH depuis PC03 .98 autorisé ; empreintes vérifiées |
| 6 | Load balancer .72 et TLS | Nom DNS, certificat et clé réels ; backends testés |
| 7 | Filtrage et DNAT TCP 443 sur R1 puis FW1 | Seul .72 publié ; tests externes et refus |

Depuis `Config_Ansible`, sur le poste de contrôle autorisé :

```sh
ansible-inventory --graph
ansible-playbook fronts.yml --syntax-check
ansible fronts -m ping
ansible-playbook fronts.yml
```

Le playbook installe Nginx et son contenu ; il n'attribue pas les IP système.
Les backends écoutent en HTTP interne, acceptent le load balancer .72 et
localhost ; aucun accès direct HTTP client. Ne pas ouvrir leur HTTP sur le WAN.
Le compte root de l'inventaire nécessite une authentification SSH existante.
Vérifier les empreintes SSH lors du premier raccordement et après réadressage.

Installer ensuite le modèle `../loadbalancer.conf.example` sur .72, avec les
valeurs TLS réelles, vérifier `nginx -t` puis recharger Nginx. Tester :

- Depuis .72 : HTTP vers chacun des trois backends et `/healthz` réussit.
- Depuis un autre hôte DMZ : HTTP et `/healthz` directs renvoient 403.
- Depuis un client autorisé : HTTPS sur le nom public/privé du load balancer fonctionne.
- Depuis Internet : seul TCP 443 publié ; ni .70, ni DNS, ni backends, ni administration.
- Depuis DMZ : nouvelle connexion LAN refusée ; sorties autorisées et retours fonctionnels.

Pour les clients internes, un enregistrement DNS interne pointant vers .72
évite de dépendre d'un hairpin NAT non défini. Les certificats doivent couvrir
le nom utilisé. Conserver les résultats et sauvegarder après recette.
