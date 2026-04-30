extends Node

# ==================== ИГРА ====================
const DB_NAME := "shawarama.db"

# ==================== НАГРАДЫ ====================
const SHAWU_REWARD := 250

# ==================== АНИМАЦИИ ====================
const ANIM_FADE_DURATION := 0.25
const ANIM_SCALE_DURATION := 0.2
const ANIM_EXIT_DURATION := 0.3
const ANIM_EXIT_OFFSET := 200.0
const EXIT_DELAY := 1.0
const GRILL_MOVE_DURATION := 0.5

# ==================== LAVASH ====================
const LAVASH_SCALE := Vector2(1.0, 1.0)

# Граммовка ингредиентов (максимальная)
const INGREDIENT_MAX_WEIGHTS := {
	"meat": 100,     # 100г мяса
	"tomato": 50,    # 50г помидоров
	"salad": 50,     # 50г салата
	"cheese": 30,    # 30г сыра
	"onion": 25,     # 25г лука
	"pepper": 20     # 20г перца
}

# ==================== KITCHEN ====================
const POUR_INTERVAL := 0.15  

# ==================== KITCHEN WRAP ====================
const PACKAGE_WIDTH := 195
const PACKAGE_HEIGHT := 290

# ==================== HALL ====================
const DELIVERY_DISTANCE := 130.0
const Z_INDEX_SHAWU := 100

# ==================== GHOST СПРАЙТЫ ====================
const GHOST_MODULATE := Color(1, 1, 1, 0.7)
const GHOST_Z_INDEX := 1000
