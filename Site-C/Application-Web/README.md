# Application Web

| Service | Hôte | Réseau / adresse | Passerelle |
|---|---|---|---|
| Web 1 | Proxmox 1 | VLAN 30 — 172.16.2.69/27 | 172.16.2.65 |
| Web 2 | Proxmox 1 | VLAN 30 — 172.16.2.71/27 | 172.16.2.65 |
| Reverse proxy | Proxmox 2 | DMZ — 172.16.3.162/27 | 172.16.3.161 (Hillstone) |

Chemin : client → switch L3 → Hillstone → reverse proxy → Hillstone → Web 1 ou Web 2.

La VM proxy utilise uniquement le bridge DMZ de la deuxième carte de Proxmox 2. Les deux Web utilisent le bridge LAN de Proxmox 1. La gestion des trois nœuds Proxmox reste dans le VLAN 30.

Configurer les cibles du proxy sur .69 et .71 (HTTP/HTTPS selon l'application). La configuration applicative et les certificats restent à déployer. La HA des VM exige aussi stockage, quorum et disponibilité des réseaux : voir le [dossier réseau](../Infrastructure/docs/Dossier_reseau.md).
