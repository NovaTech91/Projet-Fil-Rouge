# Site B - Infrastructure et application Web

Référence : [SITE_B_Schema.pdf, version 1.1](Infrastructure/docs/SITE_B_Schema.pdf).
Le bloc LAN `172.16.1.0/24` est subdivisé ; il ne doit pas être configuré comme
un réseau connecté supplémentaire. La DMZ utilise `172.16.3.64/26`.

## Architecture

```text
Internet -- R1 port 1 (WAN à relever, NAT)
             port 4 : 172.16.1.193/30
                       |
             FW1 e0/0 : 172.16.1.194/30 (AMONT)
                 e0/1 : 172.16.3.65/26  (DMZ)
                 e0/2 : 172.16.1.197/30 (LAN)
                       |
             SW1 port 24 : 172.16.1.198/30 (routé, sans trunk)
                 SVI VLAN 10/20/30/40/50/99 et ACL inter-VLAN
```

SW1 assure le routage inter-VLAN. FW1 filtre LAN, DMZ et amont.
La seule publication Internet est HTTPS vers le load balancer `172.16.3.72`.
R1 port 5 (`172.16.1.226/28`) et FW1 e0/3 (`172.16.1.241/28`) appartiennent
à deux réseaux de maintenance distincts. SW1 reste géré sur sa SVI VLAN 99
`172.16.1.161/27` ; les VTY contrôlent les sessions SSH et ne portent pas d'IP.

## Documents et configurations

| Document | Usage |
| --- | --- |
| [Dossier réseau](Infrastructure/docs/Dossier_reseau.md) | Adressage, câblage, services, filtrage, migration et recette |
| [Configurations](Infrastructure/configuration/README.md) | Fichiers disponibles, paramètres manquants et limites |
| [SW1.conf](Infrastructure/configuration/SW1.conf) | SVI /27, transit /30, DHCP, ACL Wi-Fi et restriction VTY |
| [R1 et FW1](Infrastructure/configuration/R1_FW1.md) | Interfaces, routes, NAT et règles à saisir selon le modèle |
| [Services](Infrastructure/configuration/Services.md) | Réseau des hôtes, DHCP, DNS et load balancer |
| [Déploiement DMZ](Infrastructure/configuration/DMZ/memo_ordre_déploiement.md) | Ordre des opérations et commandes Ansible |
| [Cahier des charges Web](Application-Web/CDC/CDC_yanis.md) | Exigences applicatives et accès administration |

Les configurations sont une cible à adapter au matériel et à tester ; aucun
équipement n'a été modifié. Le filtre fourni pour SW1 couvre le Wi-Fi et les
sources VTY ; les autres ACL de la matrice restent à traduire selon les services
réellement déployés. Ne pas considérer ces exemples comme une isolation complète.
L'ancien visuel [Schema SRV.png](Infrastructure/docs/Schema%20SRV.png) est
historique : voir [le statut des documents](Infrastructure/docs/README.md).
