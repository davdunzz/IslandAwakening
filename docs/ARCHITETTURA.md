# Architettura

- `main.gd`: menu, impostazioni, Lore e avvio partita.
- `world.gd`: generazione ottimizzata dell'isola e dei punti di interesse.
- `player_controller.gd`: locomozione e interazione FPS.
- `weapon_system.gd`: combattimento, armi e munizioni.
- `enemy_ai.gd`: stato dei nemici e combattimento.
- `mission_manager.gd`: progressione delle dieci missioni.
- `save_manager.gd`: salvataggi e impostazioni.
- `network_manager.gd`: host/client LAN ENet.
- `hud.gd`: interfaccia di gioco.

Il mondo usa scene e script riutilizzabili, collisioni semplici e materiali economici per funzionare su PC di fascia media.
