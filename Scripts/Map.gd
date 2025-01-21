extends TileMapLayer

# Tiles
var allTiles: Array
var selectedTile: Vector2i = Vector2i(-1, -1)
var tilesPerTurn: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var main: Node = get_node("/root/Main")
@onready var hud: Node = get_node("/root/Main/HUD")

var firstOpponentTileConquered: bool = false
var firstOpponentMoreResources: bool = false
var firstStructureBuilt: bool = false
var firstResourceStructureBuilt: bool = false
var firstVillageConquered: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# set seed for random number generator
	#rng.set_seed(1)

	# get all tiles on the map
	allTiles = get_used_cells()
	# set terrain for each tile randomly according weighted distribution
	for tile in allTiles:
		set_cells_terrain_connect([tile], 0, _get_terrain_type())
	
	# set capitals
	set_cells_terrain_connect([Config.player.startingTile], Config.player.terrain_id, Config.capital.terrain_id)
	set_cells_terrain_connect([Config.opponent.startingTile], Config.opponent.terrain_id, Config.capital.terrain_id)

	# check that not all tiles around capital are uncapturable
	var capital_surroundings: Array = get_surrounding_cells(Config.player.startingTile)
	var capturable: int = len(capital_surroundings.filter(func(x): return x in Config.capturable_tiles))
	while(capturable < 3):
		for tile in capital_surroundings:
			set_cells_terrain_connect([tile], 0, _get_terrain_type())
		capturable = len(get_surrounding_cells(Config.player.startingTile).filter(
			func(x): return get_cell_tile_data(x).terrain in Config.capturable_tiles))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# Handle input events
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			# locate event and transform to map coordiantes
			var coordinates = get_global_transform_with_canvas().affine_inverse() * event.position
			var pos_clicked = local_to_map(coordinates)
			
			# check if clicked tile is on the map
			if pos_clicked in allTiles:
				selectedTile = pos_clicked
				
				# own tile clicked, show possible options
				if pos_clicked in get_owned_tiles(main.currentPlayer):
					clear_all_tiles()
					var placable_structures: Array = get_placable_structures(pos_clicked)
					hud.set_buttons_visibility(placable_structures)
					if tilesPerTurn < Config.maxTilesPerTurn:
						mark_possible_tiles(pos_clicked)
					if len(placable_structures) > 0 or tilesPerTurn < Config.maxTilesPerTurn:
						set_cell(pos_clicked, get_cell_source_id(pos_clicked), \
							get_cell_atlas_coords(pos_clicked), 2)
				else:
					# surrounding tile clicked
					if get_cell_alternative_tile(pos_clicked) == 1:
						clear_all_tiles()
						# conquer the selected tile if possible
						conquer_tile(pos_clicked)
						# remove tiles that are not connected anymore
						remove_disconnected_tiles()
						# update players resource benefit
						main.calculate_resources()
					
					clear_all_tiles()
					hud.update_hud()
					selectedTile = Vector2i(-1,-1)

# Get terrain_id of random selected tile
func _get_terrain_type() -> int:
	var remaining_distance = rng.randf()
	for i in Config.tiles.size():
		remaining_distance -= Config.tiles[i][1]
		if remaining_distance < 0:
			return Config.tiles[i][0]
	return 0

# Mark tiles that can be conquered
func mark_possible_tiles(pos_clicked: Vector2i) -> void:
	var ownedTiles = get_owned_tiles(main.currentPlayer)
	# Surrounding tiles
	if pos_clicked in allTiles and pos_clicked in ownedTiles:
		for cell in get_surrounding_cells(pos_clicked):
			if cell in allTiles and cell not in ownedTiles \
				and get_cell_tile_data(cell).terrain in Config.capturable_tiles:
				# to conquer an opponnent possessed tile, a camp needs to be next to it
				#if get_cell_tile_data(cell).terrain_set != 0:
					#if Config.camp.terrain_id in get_surrounding_cells(pos_clicked).map(
						#func(x): return get_cell_tile_data(x).terrain and \
						#get_cell_tile_data(x).terrain_set == main.currentPlayer.terrain_id):
						#pass
					#else:
						#continue
				set_cell(cell, get_cell_source_id(cell), \
					get_cell_atlas_coords(cell), (get_cell_alternative_tile(cell) + 1) %  2)

# Reset all marked tiles
func clear_all_tiles() -> void:
	for cell in allTiles:
		set_cell(cell, get_cell_source_id(cell), get_cell_atlas_coords(cell), 0)

# Get owned tiles of player
func get_owned_tiles(player: Player.PlayerObject) -> Array:
	return get_used_cells().filter(func(x): return get_cell_tile_data(x).terrain_set == player.terrain_id)

# Get amount of owned tiles of this type
func get_number_of_owned_tiles_by_terrain(terrain: int) -> int:
	return len(get_owned_tiles(main.currentPlayer).filter(func(x): return get_cell_tile_data(x).terrain == terrain))

# Check if structure can be placed on tile
func get_placable_structures(tile: Vector2i) -> Array:
	var placeable: Array = []
	for structure in Config.placable_structures:
		if tile in get_owned_tiles(main.currentPlayer) and \
			get_cell_tile_data(tile).terrain in structure.placedOnTiles and \
			main.currentPlayer.lumber >= structure.lumber and \
			main.currentPlayer.stone >= structure.stone and \
			main.currentPlayer.grain >= structure.grain and \
			main.currentPlayer.gold >= structure.gold and \
			(structure.adjacentTileType == -1 or structure.adjacentTileType in \
			get_surrounding_cells(tile).filter(func(x): return x in allTiles).map(
				func(x): return get_cell_tile_data(x).terrain)):
			placeable.append(structure)
	return placeable

# Place strucutre on currently selected tile
func place_structure(structure: Structure.StructureObject) -> void:
	clear_all_tiles()
	set_cells_terrain_connect([selectedTile], main.currentPlayer.terrain_id, structure.terrain_id)
	main.currentPlayer.lumber -= structure.lumber
	main.currentPlayer.stone -= structure.stone
	main.currentPlayer.grain -= structure.grain
	main.currentPlayer.gold -= structure.gold
	main.calculate_resources()
	
	# increase the price of the structure
	structure.lumber += structure.lumberCostPerTurn
	structure.stone += structure.stoneCostPerTurn
	structure.grain += structure.grainCostPerTurn
	structure.gold += structure.goldCostPerTurn
	
	# update hud
	hud.update_hud()
	
	# story
	if (get_number_of_owned_tiles_by_terrain(Config.camp.terrain_id) > 0 \
		or get_number_of_owned_tiles_by_terrain(Config.tower.terrain_id) > 0) \
		and not firstStructureBuilt:
		main.display_story("The first defense structure was built! It provides defensive advantages and fortifies the territory!")
		firstStructureBuilt = true
	elif (get_number_of_owned_tiles_by_terrain(Config.farm.terrain_id) > 0 \
		or get_number_of_owned_tiles_by_terrain(Config.mine.terrain_id) > 0) \
		and not firstResourceStructureBuilt:
		main.display_story("The first production site was built! It harvests resources and helps expanding the empire	!")
		firstResourceStructureBuilt = true

# Things to do on the end of a turn
func end_turn() -> void:
	clear_all_tiles()
	# remove tiles that are not connected anymore
	remove_disconnected_tiles()
	tilesPerTurn = 0
	
	# story
	if not Config.multiplayerSelected:
		if Config.opponent.lumber > Config.player.lumber + 10 and not firstOpponentMoreResources:
			main.display_story("Your opponent is pulling ahead with a significant resource advantage! Focus on gathering resources and turn the tide!")
			firstOpponentMoreResources = true

# Conquer tile
func conquer_tile(pos_clicked: Vector2) -> void:
	var pos_clicked_data = get_cell_tile_data(pos_clicked)
	
	if pos_clicked_data.terrain in Config.capturable_tiles:
		# destroy camp if captured
		if pos_clicked_data.terrain == Config.camp.terrain_id:
			set_cells_terrain_connect([pos_clicked], 0, 	0)
		# conquer opponnent owned tile
		#elif pos_clicked_data.terrain_set != main.currentPlayer.terrain_id \
			#and pos_clicked_data.terrain_set != 0:
				## to conquer an opponnent possessed tile, a camp needs to be next to it
				#if Config.camp.terrain_id in get_surrounding_cells(pos_clicked).map(
					#func(x): return get_cell_tile_data(x).terrain \
					#and get_cell_tile_data(x).terrain_set == main.currentPlayer.terrain_id):
						#set_cells_terrain_connect([pos_clicked], main.currentPlayer.terrain_id, \
							#get_cell_tile_data(pos_clicked).terrain)
				#else:
					#return
		else:
			set_cells_terrain_connect([pos_clicked], main.currentPlayer.terrain_id, \
				pos_clicked_data.terrain)
		
		tilesPerTurn += 1
		
		# story
		if pos_clicked_data.terrain_set != main.currentPlayer.terrain_id \
			and pos_clicked_data.terrain_set != 0 and not firstOpponentTileConquered:
			main.display_story("A hostile tile was conquered.\nPrepare for the response!")
			firstOpponentTileConquered = true
		elif get_number_of_owned_tiles_by_terrain(Config.village.terrain_id) > 0 \
			and not firstVillageConquered:
			main.display_story("The first village was conquered! It provides valuable gold!")
			firstVillageConquered = true

# Conquer tile for opponent
func conquer_random_tile(player: Player.PlayerObject) -> void:
	var possibleTiles: Array = []
	var ownedTiles: Array = get_owned_tiles(player)

	for tile in ownedTiles:
		var surroundingTiles: Array = get_surrounding_cells(tile)
		for t in surroundingTiles:
			if t in allTiles and t not in ownedTiles and get_cell_tile_data(t).terrain in Config.capturable_tiles:
				possibleTiles.append(t)
	
	if len(possibleTiles) > 0:
		var tileOrder: Array = [7,8,9,5,1,0]
		for t in tileOrder:
			if t in possibleTiles.map(func(x): return get_cell_tile_data(x).terrain):
				var bestTiles: Array = possibleTiles.filter(func(x): return get_cell_tile_data(x).terrain == t)
				conquer_tile(bestTiles.pick_random())
				return

# Place structure for opponent
func place_random_structure(player: Player.PlayerObject) -> void:
	var ownedTiles: Array = get_owned_tiles(player)
	var tileOrder: Array = [0,1]
	for t in tileOrder:
		if t in ownedTiles.map(func(x): return get_cell_tile_data(x).terrain):
			var bestTiles = ownedTiles.filter(func(x): return get_cell_tile_data(x).terrain == t)
			selectedTile = bestTiles.pick_random()
			var possibleStructures: Array = get_placable_structures(selectedTile)
			if len(possibleStructures) > 0:
				possibleStructures.reverse()
				place_structure(possibleStructures[0])
				return

# Recursively check if the tile is connected to the capital
func is_connected_to_capital(connected: Array, tile: Vector2i, owned: Array) -> Array:
	var neighbors = get_surrounding_cells(tile).filter(func(x): return x in owned)
	for n in neighbors:
		if n not in connected:
			connected.append(n)
			connected = is_connected_to_capital(connected, n, owned)
	return connected

# Remove tiles that are no longer connected to the capital
func remove_disconnected_tiles() -> void:
	var lost : Array = []
	
	# player
	var ownedTiles : Array = get_owned_tiles(Config.player)
	var connected : Array = is_connected_to_capital([Config.player.startingTile], Config.player.startingTile, ownedTiles)
	
	for tile in ownedTiles:
		if tile not in connected:
			lost.append(tile)
	
	# opponent
	ownedTiles = get_owned_tiles(Config.opponent)
	connected = is_connected_to_capital([Config.opponent.startingTile], Config.opponent.startingTile, ownedTiles)

	for tile in ownedTiles:
		if tile not in connected:
			lost.append(tile)
	
	# reset all disconnected tiles
	for tile in lost:
		set_cells_terrain_connect([tile], 0, get_cell_tile_data(tile).terrain)
