extends CanvasLayer


# main node to access functions and values
@onready var main: Node = get_node("/root/Main")

# map node to get progress
@onready var map: Node = get_node("/root/Main/SubViewportContainer/SubViewport/Map")


# text displaying the current turn
@onready var turn: Label = get_node("Progress/TurnLabel")
@onready var tile: Label = get_node("Progress/TileLabel")

# progress bar displaying the relative amount of conquered territory
@onready var labelPlayer1: Label = get_node("Progress/LabelPlayer1")
@onready var labelPlayer2: Label = get_node("Progress/LabelPlayer2")
@onready var progressBarPlayer1: ProgressBar = get_node("Progress/ProgressBarPlayer1")
@onready var progressBarPlayer2: ProgressBar = get_node("Progress/ProgressBarPlayer2")
@onready var progressLabelPlayer1: Label = get_node("Progress/ProgressLabelPlayer1")
@onready var progressLabelPlayer2: Label = get_node("Progress/ProgressLabelPlayer2")

# text displaying the resources
@onready var resourceAmount1: Label = get_node("Resources/Amounts/Label1")
@onready var resourceAmount2: Label = get_node("Resources/Amounts/Label2")
@onready var resourceAmount3: Label = get_node("Resources/Amounts/Label3")
@onready var resourceAmount4: Label = get_node("Resources/Amounts/Label4")

# text displaying the increase of the resources
@onready var resourceIncrease1: Label = get_node("Resources/Increases/Label1")
@onready var resourceIncrease2: Label = get_node("Resources/Increases/Label2")
@onready var resourceIncrease3: Label = get_node("Resources/Increases/Label3")
@onready var resourceIncrease4: Label = get_node("Resources/Increases/Label4")

# buttons to place structures
@onready var structureButton1: Button = get_node("Structures/Buttons/Button1")
@onready var structureButton2: Button = get_node("Structures/Buttons/Button2")
@onready var structureButton3: Button = get_node("Structures/Buttons/Button3")
@onready var structureButton4: Button = get_node("Structures/Buttons/Button4")

# text displaying the cost of structures
@onready var structureCost1: Label = get_node("Structures/Labels/Control1/CenterContainer/HBoxContainer/CostLabel")
@onready var structureCost2: Label = get_node("Structures/Labels/Control2/CenterContainer/HBoxContainer/CostLabel")
@onready var structureCost3: Label = get_node("Structures/Labels/Control3/CenterContainer/HBoxContainer/CostLabel")
@onready var structureCost4: Label = get_node("Structures/Labels/Control4/CenterContainer/HBoxContainer/CostLabel")

# button to end current turn
@onready var endTurnButton: Node = get_node("EndTurnButton")

# export button
@onready var exportButton: Node = get_node("Buttons/ExportButton")


func init_hud() -> void:
	# update the HUD when the game starts
	update_hud()
	
	if Config.multiplayerSelected:
		labelPlayer2.text = "Player 2"

# updates the hud to show the current values
func update_hud():
	
	# set the amount of the resources
	resourceAmount1.text = str(main.currentPlayer.lumber)
	resourceAmount2.text = str(main.currentPlayer.stone)
	resourceAmount3.text = str(main.currentPlayer.grain)
	resourceAmount4.text = str(main.currentPlayer.gold)
	
	# set the increase of the resources
	resourceIncrease1.text = "(+" + str(main.currentPlayer.lumberPerTurn) + ")"
	resourceIncrease2.text = "(+" + str(main.currentPlayer.stonePerTurn) + ")"
	resourceIncrease3.text = "(+" + str(main.currentPlayer.grainPerTurn) + ")"
	resourceIncrease4.text = "(+" + str(main.currentPlayer.goldPerTurn) + ")"
	
	# set cost of structures
	structureCost1.text = Config.camp.cost_string()
	structureCost2.text = Config.tower.cost_string()
	structureCost3.text = Config.farm.cost_string()
	structureCost4.text = Config.mine.cost_string()
	
	# set number of turn
	turn.text = str(main.currentPlayer.terrain_id) + ": Turn " + str(main.turnNumber)
	if Config.gameMode == 0:
		turn.text += " / " + str(Config.maxNumberOfTurns)
	
	tile.text = str(map.tilesPerTurn) + " / " + str(Config.maxTilesPerTurn) + " Tiles"
	
	# set progress bar
	progressBarPlayer1.value = len(map.get_owned_tiles(Config.player)) * 200 / 397
	progressBarPlayer2.value = len(map.get_owned_tiles(Config.opponent)) * 200  / 397
	progressLabelPlayer1.text = str(len(map.get_owned_tiles(Config.player)))
	progressLabelPlayer2.text = str(len(map.get_owned_tiles(Config.opponent)))
	
	# hide structures
	set_buttons_visibility([])

# Set state of buttons
func set_buttons_visibility(structures: Array) -> void:
	# reset all buttons
	structureButton1.disabled = true
	structureButton2.disabled = true
	structureButton3.disabled = true
	structureButton4.disabled = true
	# set possible buttons
	if Config.camp in structures:
		structureButton1.disabled = false
	if Config.tower in structures:
		structureButton2.disabled = false
	if Config.farm in structures:
		structureButton3.disabled = false
	if Config.mine in structures:
		structureButton4.disabled = false

# Quit the current game
func _on_QuitButton_pressed() -> void:
	main.end_game(true)

# Reset the current turn
func _on_ResetTurnButton_pressed() -> void:
	main.import_data(Config.currentState)
	map.tilesPerTurn = 0
	update_hud()

# Called when the "End Turn" button is pressed
func _on_EndTurnButton_pressed() -> void:
	main.end_turn()

# Place camp
func _on_button_1_pressed() -> void:
	map.place_structure(Config.camp)
	update_hud()

# Place tower
func _on_button_2_pressed() -> void:
	map.place_structure(Config.tower)
	update_hud()

# Place farm
func _on_button_3_pressed() -> void:
	map.place_structure(Config.farm)
	update_hud()

# Place mine
func _on_button_4_pressed() -> void:
	map.place_structure(Config.mine)
	update_hud()

# Export the game state
func _on_exportButton_pressed() -> void:
	$/root/Main/TextEdit.text = main.export_data()
	$/root/Main/TextEdit.visible = not $/root/Main/TextEdit.visible
	
	if exportButton.text != "Export":
		exportButton.text = "Export"
	else:
		exportButton.text = "Hide\nExport"
