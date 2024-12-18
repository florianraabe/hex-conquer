extends Node2D

var currentPlayer: Player.PlayerObject = Config.player
var turnNumber: int = 1
var tutorialStep: int = 0

var game_over: bool = false

# Components
@onready var hud: Node = get_node("HUD")
@onready var map: Node = get_node("SubViewportContainer/SubViewport/Map")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if Config.import:
		import_data(Config.importData)
	
	hud.init_hud()
	Config.currentState = export_data()
	
	if Config.tutorial:
		$TutorialDialog.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called when the game is over
func end_game() -> void:
	# different game modes
	if Config.gameMode == 0:
		if len(map.get_owned_tiles(Config.player)) <= len(map.get_owned_tiles(Config.opponent)):
			Config.winner = Config.opponent
		else:
			Config.winner = Config.player
	elif Config.gameMode == 1:
		Config.winner = currentPlayer
	
	# reset players
	Config.player.reset_player()
	Config.opponent.reset_player()
	
	# reset structures
	for s in Config.placable_structures:
		s.reset_structure()
	
	# reset other config data
	Config.import = false
	Config.multiplayerSelected = false
	Config.tutorial = false
	
	# make a restart possible
	Config.gameOver = true
	
	# change to ending story
	get_tree().change_scene_to_file("res://Scenes/Story.tscn")


# Called when the player ends the turn
func end_turn() -> void:
	
	# different game modes
	if Config.gameMode == 0:
		# check if game has ended
		if turnNumber >= Config.maxNumberOfTurns:
			if Config.multiplayerSelected and currentPlayer == Config.opponent or not Config.multiplayerSelected:
				end_game()
				return
	elif Config.gameMode == 1:
		if currentPlayer.gold >= Config.maxNumberOfResource:
			end_game()
			return
	
	# update the resources of the player
	calculate_resources()
	currentPlayer.update_resources()
	
	# change current player
	if currentPlayer == Config.player:
		currentPlayer = Config.opponent
	elif currentPlayer == Config.opponent:
		currentPlayer = Config.player
		turnNumber += 1
	
	if currentPlayer == Config.opponent:
		# if singleplayer, execute the bot
		if not Config.multiplayerSelected:
			# conquer random tiles
			for i in range(0, Config.maxTilesPerTurn):
				map.conquer_random_tile(Config.opponent)
				map.place_random_structure(Config.opponent)
			end_turn()
	
	# update map
	map.end_turn()
	# update the HUD
	hud.update_hud()
	
	Config.currentState = export_data()

# Calculate the amount of resources the player gets next turn
func calculate_resources() -> void:
	currentPlayer.lumberPerTurn = map.get_number_of_owned_tiles_by_terrain(1)
	currentPlayer.stonePerTurn = map.get_number_of_owned_tiles_by_terrain(Config.mine.terrain_id)
	currentPlayer.grainPerTurn = map.get_number_of_owned_tiles_by_terrain(Config.farm.terrain_id)
	currentPlayer.goldPerTurn = map.get_number_of_owned_tiles_by_terrain(Config.village.terrain_id)

# Display story in game
func display_story(text: String) -> void:
	$Window/RichTextLabel.text = text
	$Window.visible = true

# Close window
func _on_close_requested() -> void:
	$Window.visible = false

# Export the data of the game
func export_data() -> String:
	var map_list = []
	for t in map.allTiles:
		map_list.append({
			"x": t.x,
			"y": t.y,
			"terrain": map.get_cell_tile_data(t).terrain, 
			"terrain_set": map.get_cell_tile_data(t).terrain_set
		})
	
	var player_dict = {}
	player_dict["player"] = Config.player.get_data_dict()
	player_dict["opponent"] = Config.opponent.get_data_dict()
	
	var structure_dict = {}
	structure_dict["capital"] = Config.capital.get_data_dict()
	structure_dict["camp"] = Config.camp.get_data_dict()
	structure_dict["tower"] = Config.tower.get_data_dict()
	structure_dict["village"] = Config.village.get_data_dict()
	structure_dict["farm"] = Config.farm.get_data_dict()
	structure_dict["mine"] = Config.mine.get_data_dict()
	
	var meta_dict = {}
	meta_dict["turnNumber"] = turnNumber
	meta_dict["currentPlayer"] = currentPlayer.terrain_id
	meta_dict["gameMode"] = Config.gameMode
	meta_dict["multiplayerSelected"] = Config.multiplayerSelected
	
	var export_string = "{"
	export_string += "\"map\":" + str(JSON.stringify(map_list)) + ","
	export_string += "\"player\":" + str(JSON.stringify(player_dict)) + ","
	export_string += "\"structures\":" + str(JSON.stringify(structure_dict)) + ","
	export_string += "\"meta\":" + str(JSON.stringify(meta_dict))
	export_string += "}"
	
	return export_string


func import_data(importData: String) -> void:
	var json = JSON.new()
	var import_status = json.parse(importData)
	if import_status == OK:
		var data_received = json.data
		# map data
		for tile in data_received.map:
			map.set_cells_terrain_connect([Vector2i(tile.x, tile.y)], tile.terrain_set, tile.terrain)
		# player data
		Config.player.set_data_dict(data_received.player.player)
		Config.opponent.set_data_dict(data_received.player.opponent)
		# structure data
		Config.capital.set_data_dict(data_received.structures.capital)
		Config.camp.set_data_dict(data_received.structures.camp)
		Config.tower.set_data_dict(data_received.structures.tower)
		Config.village.set_data_dict(data_received.structures.village)
		Config.farm.set_data_dict(data_received.structures.farm)
		Config.mine.set_data_dict(data_received.structures.mine)
		# meta data
		turnNumber = data_received.meta.turnNumber
		if data_received.meta.currentPlayer == 1:
			currentPlayer = Config.player
		else:
			currentPlayer = Config.opponent
		Config.gameMode = data_received.meta.gameMode
		Config.multiplayerSelected = data_received.meta.multiplayerSelected
	else:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())

func tutorial() -> void:
	
	if tutorialStep == 0:
		$SubViewportContainer/SubViewport/Camera.zoom = Vector2(4,4)
		$SubViewportContainer/SubViewport/Camera.offset = Vector2(0,475)
		$TutorialDialog.dialog_text = "You start at the bottom with the blue capital.\n"
		$TutorialDialog.dialog_text += "Click on it to see tiles you can conquer!\n"
		$TutorialDialog.dialog_text += "If you click on a tile that is highlighted green,\nyou can conquer it."
		$TutorialDialog.position.x = 100
		$TutorialDialog.position.y = 100
	elif tutorialStep == 1:
		$TutorialDialog.dialog_text = "You can conquer 5 tiles per turn.\n"
		$TutorialDialog.dialog_text += "The progress bar shows the amount of tiles\nyou and your opponent control.\n"
		$TutorialDialog.dialog_text += "You can also see whos turn it is."
		$TutorialDialog.position.x = 970
	elif tutorialStep == 2:
		$TutorialDialog.dialog_text = "Here you can see your resources.\n"
		$TutorialDialog.dialog_text += "The green numbers show how many resources\nyou will get with the next turn."
		$TutorialDialog.position.y = 400
	elif tutorialStep == 3:
		$TutorialDialog.dialog_text = "With the buttons on the right\nyou can build different structures.\n"
		$TutorialDialog.dialog_text += "The costs for the build are displayed below.\n"
		$TutorialDialog.dialog_text += "You can only click on them i\nyou have enough resources!"
		$TutorialDialog.position.y = 700
	elif tutorialStep == 4:
		$TutorialDialog.dialog_text = "To finish your turn, press this button.\n"
		$TutorialDialog.dialog_text += "You can export your game with the link below.\n"
		$TutorialDialog.dialog_text += "Just copy the text and save it somewhere!"
		$TutorialDialog.position.y = 850
	elif tutorialStep == 5:
		$TutorialDialog.dialog_text = "That's it!\n"
		$TutorialDialog.dialog_text += "Good luck conquering the hex tiles!"
		$TutorialDialog.position.x = 760
		$TutorialDialog.position.y = 465
	elif tutorialStep >= 6:
		$TutorialDialog.visible = false

	tutorialStep += 1
