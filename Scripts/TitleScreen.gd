extends Control


func _on_VersionLabel_ready() -> void:
	get_node("/root/TitleScreen/VersionLabel").text = "version " + str(Config.version)

func _on_StartButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_ModeButton_pressed() -> void:
	var text: String = get_node("/root/TitleScreen/Buttons/ModeButton").text
	if text == Config.gameModes[0]:
		get_node("/root/TitleScreen/Buttons/ModeButton").text = Config.gameModes[1]
		get_node("/root/TitleScreen/Buttons/ModeButton").set_text(Config.gameModes[1])
		Config.gameMode = 1
	else:
		get_node("/root/TitleScreen/Buttons/ModeButton").text = Config.gameModes[0]
		get_node("/root/TitleScreen/Buttons/ModeButton").set_text(Config.gameModes[0])
		Config.gameMode = 0


func _on_MultiplayerButton_pressed() -> void:
	var text: String = get_node("/root/TitleScreen/Buttons/MultiplayerButton").text
	if text == "Singleplayer":
		text = "Multiplayer"
		get_node("/root/TitleScreen/Buttons/MultiplayerButton").set_text("Multiplayer")
		Config.multiplayerSelected = true
	else:
		text = "Singleplayer"
		get_node("/root/TitleScreen/Buttons/MultiplayerButton").set_text("Singleplayer")
		Config.multiplayerSelected = false


func _on_HelpButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/HelpPage.tscn")


func _on_BackButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")


func _on_TutorialButton_pressed() -> void:
	Config.tutorial = true
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_ImportButton_pressed() -> void:
	get_node("/root/TitleScreen/Import").visible = not get_node("/root/TitleScreen/Import").visible
	get_node("/root/TitleScreen/Buttons").visible = not get_node("/root/TitleScreen/Buttons").visible
	
	if not get_node("/root/TitleScreen/Import").visible:
		Config.import = true
		Config.importData = get_node("/root/TitleScreen/Import/TextEdit").text
		get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_CancelImportButton_pressed() -> void:
	get_node("/root/TitleScreen/Import").visible = false
	get_node("/root/TitleScreen/Buttons").visible = true
