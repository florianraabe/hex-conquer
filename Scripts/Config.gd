extends Node

# --- Version ---
const version: String = "4.0.0"

# --- Import ---
var import: bool = false
var importData: String

var currentState: String

# --- Game modes ---
const gameModes: Array = ["Territory Control", "Resource Victory"]
var gameMode: int = 0
var multiplayerSelected: bool = false
var tutorial: bool = false

# Territory control
const maxNumberOfTurns: int = 50
# Resource victory
const maxNumberOfResource: int = 50

# Turn metrics
const maxTilesPerTurn: int = 5

# --- Tiles ---
# 0 - gras
# 1 - forest
# 2 - mountains
# 3 - river
# 4 - capital
# 5 - camp
# 6 - tower
# 7 - village
# 8 - farm
# 9 - mine

# Map creation, [terrain_id, probability]
const tiles: Array = [[0, 0.47], [1, 0.3], [2, 0.1], [3, 0.1], [7, 0.03]]
# Terrains the player can conquer
const capturable_tiles: Array = [0, 1, 5, 7, 8, 9]

# --- Structures ---
var capital: Structure.StructureObject = Structure.StructureObject.new(4, -1, [], 
	0, 0, 0, # lumber
	0, 0, 0, # stone
	0, 0, 0, # grain
	0, 0, 0, # gold
)
var camp: Structure.StructureObject = Structure.StructureObject.new(5, -1, [0,1], 
	5, 0, 5, # lumber
	0, 0, 0, # stone
	0, 0, 0, # grain
	0, 0, 0, # gold
)
var tower: Structure.StructureObject = Structure.StructureObject.new(6, -1, [0,1], 
	2, 0, 2, # lumber
	5, 0, 5, # stone
	2, 0, 2, # grain
	0, 0, 0, # gold
)
var village: Structure.StructureObject = Structure.StructureObject.new(7, -1, [], 
	0, 0, 0, # lumber
	0, 0, 0, # stone
	0, 0, 0, # grain
	0, 1, 0, # gold
)
var farm: Structure.StructureObject = Structure.StructureObject.new(8, 3, [0,1], 
	5, 0, 5, # lumber
	2, 0, 2, # stone
	0, 2, 0, # grain
	0, 0, 0, # gold
)
var mine: Structure.StructureObject = Structure.StructureObject.new(9, 2, [0,1], 
	5, 0, 5, # lumber
	0, 2, 0, # stone
	0, 0, 0, # grain
	0, 0, 0, # gold
)

var placable_structures: Array = [camp, tower, farm, mine]

# --- Players ---
var player: Player.PlayerObject = Player.PlayerObject.new(1, Vector2i(12, 21))
var opponent: Player.PlayerObject = Player.PlayerObject.new(2, Vector2i(12, 1))

# --- Game ---
var winner: Player.PlayerObject
var gameOver: bool = false
