extends Node

# ==================== ИГРА ====================
const DB_NAME := "shawarama.db"

# ==================== НАГРАДЫ ====================
const SHAWU_REWARD := 100

# ==================== АНИМАЦИИ ====================
const ANIM_FADE_DURATION := 0.25
const ANIM_SCALE_DURATION := 0.2
const ANIM_EXIT_DURATION := 0.3
const ANIM_EXIT_OFFSET := 200.0
const EXIT_DELAY := 1.0
const GRILL_MOVE_DURATION := 0.5

# ==================== LAVASH ====================
const LAVASH_SCALE := Vector2.ONE

# Граммовка ингредиентов
const INGREDIENT_MAX_WEIGHTS := {
	"meat": 100,     # 100г мяса
	"chicken": 100,  # 100г курицы
	"tomato": 50,    # 50г помидоров
	"salad": 50,     # 50г салата
	"cheese": 30,    # 30г сыра
	"onion": 25      # 25г лука
}

# ==================== KITCHEN ====================
const POUR_INTERVAL := 0.1  # Сыпать каждые 0.1 секунды
const POUR_GRAMS := 5       # Грамм за одно сыпание
const CLICK_GRAMS := 15     # Грамм за клик

# ==================== KITCHEN WRAP ====================
const PACKAGE_WIDTH := 194.073
const PACKAGE_HEIGHT := 291.0

# ==================== HALL ====================
const DELIVERY_DISTANCE := 130.0
const Z_INDEX_SHAWU := 100

# ==================== GHOST СПРАЙТЫ ====================
const GHOST_MODULATE := Color(1, 1, 1, 0.7)
const GHOST_Z_INDEX := 1000
