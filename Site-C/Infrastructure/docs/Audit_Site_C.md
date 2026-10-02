# Recette de la maquette

Résultats attendus, à vérifier sur le matériel ; aucun équipement n'a été configuré à distance.

| Contrôle | Attendu |
|---|---|
| Switch : VLAN et interfaces | VLAN 10/20/30/40/50/60/99 ; aucune SVI 70/71 ; Gi1/0/23 désactivé, Gi1/0/24 .5/30 |
| Adresses de transit | R1 .1 ↔ Hillstone WAN .2 ; Hillstone LAN .6 ↔ switch .5 ; pas de doublon |
| Routes | Switch défaut .6 ; Hillstone LAN via .5, défaut .1 ; R1 retours via .2 |
| Client → proxy puis chacun des Web | HTTP/HTTPS aller-retour autorisé ; session Hillstone visible |
| Client → Web directement | Refus par ACL du VLAN client |
| Proxy → autre serveur LAN en SSH | Refus Hillstone |
| Caméra → DNS / Zabbix actif | Autorisé si services présents et caméra compatible |
| Caméra → proxy ou Internet | Refus Hillstone |
| ADMIN → proxy/caméra | SSH, web et ping selon services installés |
| ADMIN → Hillstone .6 | HTTPS/SSH fonctionne ; gestion refusée depuis les autres réseaux |
| DHCP et DNS LAN | Baux et résolution corrects |
| LAN → Internet | Web/NTP autorisés, DNS externe depuis `.66` ; dépend aussi du NAT/accès opérateur R1 |
| Internet → nouvelle connexion LAN/DMZ | Refus Hillstone, aucune publication active |
| Proxmox 2 | Deux bridges séparés, seule la VM proxy est côté DMZ |

Conserver compteurs ACL, journaux et sessions du pare-feu ainsi que les résultats positifs/négatifs. Valider le bloc transit `.4/30`, les ports physiques, les IP libres et le fonctionnement avant sauvegarde. Deuxième switch/LACP et HA restent des étapes futures.
