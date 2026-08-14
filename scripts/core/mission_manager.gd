extends Node

signal mission_changed(title: String, objective: String, index: int)
signal notification(text: String)
signal lore_unlocked(index: int)

const MISSIONS := [
	{"title":"1. Risveglio sulla spiaggia","steps":[["move",1,"Muoviti usando W, A, S, D"],["look",1,"Guardati intorno con il mouse"],["jump",1,"Salta con la barra spaziatrice"],["pickup",1,"Raccogli le provviste con tasto destro o E"],["weapon",1,"Trova l'arma improvvisata"],["attack",1,"Prova ad attaccare con il tasto sinistro"],["enemy_killed",1,"Sconfiggi il primo nemico"],["shelter",1,"Raggiungi il rifugio"]],"reward":"Kit medico"},
	{"title":"2. Primo equipaggiamento","steps":[["weapon",2,"Trova la pistola"],["resource",2,"Raccogli due risorse"],["safe_zone",1,"Attiva il punto sicuro"]],"reward":"Pistola e munizioni"},
	{"title":"3. Presenze nella foresta","steps":[["forest",1,"Entra nella foresta"],["enemy_killed",3,"Sconfiggi tre presenze nella foresta"]],"reward":"Mappa della foresta"},
	{"title":"4. Il villaggio abbandonato","steps":[["village",1,"Raggiungi il villaggio abbandonato"],["document",1,"Trova il diario nel villaggio"]],"reward":"Capitolo Lore: Il villaggio"},
	{"title":"5. Scorte perdute","steps":[["enemy_camp",1,"Trova l'accampamento nemico"],["supply",3,"Recupera tre casse di rifornimenti"]],"reward":"Cure e munizioni"},
	{"title":"6. Dentro la montagna","steps":[["cave",1,"Entra nella grotta"],["enemy_killed",2,"Elimina i guardiani della grotta"],["cave_exit",1,"Trova l'uscita secondaria"]],"reward":"Fucile"},
	{"title":"7. L'accampamento ostile","steps":[["hostile_camp",1,"Raggiungi l'accampamento principale"],["enemy_killed",5,"Libera l'accampamento"]],"reward":"Chiave della torre"},
	{"title":"8. Il segnale","steps":[["component",3,"Recupera tre componenti radio"],["radio",1,"Ripara il trasmettitore"]],"reward":"Coordinate delle rovine"},
	{"title":"9. La verità dell'isola","steps":[["ruins",1,"Raggiungi le rovine"],["truth_document",1,"Recupera il documento principale"]],"reward":"Lore completa"},
	{"title":"10. La torre","steps":[["tower",1,"Raggiungi la torre"],["boss_killed",1,"Sconfiggi il Custode"],["signal",1,"Attiva il segnale di soccorso"]],"reward":"FINE: Soccorso inviato"}
]

var mission_index := 0
var step_index := 0
var step_progress := 0
var completed: Array = []
var lore: Array = [0]
var collected_ids: Array = []
var defeated_ids: Array = []

func reset() -> void:
	mission_index=0; step_index=0; step_progress=0; completed=[]; lore=[0]; collected_ids=[]; defeated_ids=[]
	_emit_current()

func register_event(event_name: String, amount := 1) -> void:
	if mission_index >= MISSIONS.size(): return
	var step: Array = MISSIONS[mission_index].steps[step_index]
	if event_name != step[0]: return
	step_progress += amount
	if step_progress >= int(step[1]):
		step_index += 1; step_progress = 0
		if step_index >= MISSIONS[mission_index].steps.size(): _complete_mission()
		else: notification.emit("Obiettivo completato"); _emit_current()
	else: _emit_current()

func expects_event(event_name:String)->bool:
	if mission_index>=MISSIONS.size():return false
	return str(MISSIONS[mission_index].steps[step_index][0])==event_name

func _complete_mission() -> void:
	completed.append(mission_index)
	if not lore.has(mission_index + 1): lore.append(mission_index + 1); lore_unlocked.emit(mission_index + 1)
	notification.emit("MISSIONE COMPLETATA — %s" % MISSIONS[mission_index].reward)
	mission_index += 1; step_index = 0; step_progress = 0
	_emit_current()

func _emit_current() -> void:
	if mission_index >= MISSIONS.size(): mission_changed.emit("AVVENTURA COMPLETATA", "Il segnale è stato inviato. Esplora liberamente l'isola.", mission_index); return
	var mission: Dictionary = MISSIONS[mission_index]
	var step: Array = mission.steps[step_index]
	var suffix := " (%d/%d)" % [step_progress, int(step[1])] if int(step[1]) > 1 else ""
	mission_changed.emit(mission.title, str(step[2]) + suffix, mission_index)

func current_text() -> Dictionary:
	if mission_index >= MISSIONS.size(): return {"title":"Avventura completata","objective":"Esplora liberamente l'isola"}
	var step: Array = MISSIONS[mission_index].steps[step_index]
	return {"title":MISSIONS[mission_index].title,"objective":step[2]}

func serialize_state() -> Dictionary:
	return {"mission_index":mission_index,"step_index":step_index,"step_progress":step_progress,"completed":completed,"lore":lore,"collected_ids":collected_ids,"defeated_ids":defeated_ids}

func restore_state(data: Dictionary) -> void:
	mission_index=int(data.get("mission_index",0)); step_index=int(data.get("step_index",0)); step_progress=int(data.get("step_progress",0)); completed.assign(data.get("completed",[])); lore.assign(data.get("lore",[0])); collected_ids.assign(data.get("collected_ids",[])); defeated_ids.assign(data.get("defeated_ids",[])); _emit_current()
