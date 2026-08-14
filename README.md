# Island Awakening

Avventura survival in prima persona, 3D e open world, realizzata con **Godot 4.7.1** e GDScript.

## Contenuti inclusi

- Isola esplorabile con spiaggia, foresta, villaggio, grotta, campo ostile, rovine e torre.
- Menu moderno con Nuova partita, Continua, Impostazioni, Lore, LAN ed Esci.
- Dieci missioni collegate, tutorial contestuale e salvataggio automatico.
- Movimento FPS, corsa, salto, accovacciamento e mouse look.
- Mazza, pistola e fucile; munizioni, ricarica, rinculo, headshot e hit marker.
- Nemici con pattuglia, vista, inseguimento, attacco, salute, drop e boss.
- Inventario, cure, risorse, documenti, componenti e provviste.
- HUD, mirino, salute, stamina, obiettivo, mappa, inventario e pausa.
- Host/client ENet per una base multiplayer LAN separata dalla campagna offline.
- Build Windows automatica con GitHub Actions.

## Avvio nell'editor

1. Scarica [Godot 4.7.1](https://godotengine.org/download/).
2. Avvia Godot e scegli **Importa**.
3. Seleziona `project.godot`.
4. Premi **F6/F5** o il pulsante Play.

## Comandi

| Comando | Azione |
|---|---|
| WASD | Movimento |
| Mouse | Visuale |
| Spazio | Salto |
| Shift | Corsa |
| C / Ctrl | Accovacciarsi |
| Mouse sinistro | Attacco |
| Mouse destro / E | Interazione e raccolta |
| R | Ricarica |
| 1, 2, 3 | Cambia arma |
| Tab | Inventario |
| M | Mappa e missioni |
| ESC | Pausa |
| F5 | Salvataggio manuale |
| F9 (in pausa) | Menu principale |

## Esportazione Windows

Da Godot: **Progetto → Esporta → Windows Desktop → Esporta progetto**.

Da GitHub: carica tutti i file mantenendo la struttura, apri **Actions**, seleziona `Crea gioco Windows`, avvia il workflow e scarica `IslandAwakening-Windows` dagli Artifacts.

## Stato della versione

Questa è una versione completa e giocabile in stile low-poly/procedurale, studiata per rimanere molto leggera. Il modulo LAN crea e raggiunge sessioni ENet, ma la replica completa di tutti i personaggi e della campagna cooperativa è predisposta come sviluppo successivo. Gli asset visivi inclusi sono placeholder originali generati dal progetto; consultare `ASSET_CREDITS.md` per sostituirli con pacchetti CC0 fotorealistici.
