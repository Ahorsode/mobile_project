-- SQL Schema for PyQuest Gamification Layer

-- Main table for user stats
CREATE TABLE UserProgress (
    id INTEGER PRIMARY KEY DEFAULT 1,
    total_xp INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    streak_count INTEGER DEFAULT 0,
    last_login_date TEXT, -- Store as ISO8601 string
    character_name TEXT DEFAULT 'Data Knight',
    current_tier_id INTEGER DEFAULT 1
);

-- Tracks completion and scores for each lesson
CREATE TABLE LessonStatus (
    lesson_id TEXT PRIMARY KEY,
    is_completed INTEGER DEFAULT 0, -- 0 for false, 1 for true
    quiz_score REAL DEFAULT 0.0,
    is_boss_defeated INTEGER DEFAULT 0,
    mastered INTEGER DEFAULT 0
);

-- Inventory of unlocked digital items
CREATE TABLE Inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id TEXT UNIQUE,
    item_name TEXT NOT NULL,
    item_type TEXT, -- e.g., 'shield', 'cape', 'staff'
    unlocked_at TEXT
);

-- Pre-populated items or sample query to add items:
-- INSERT INTO Inventory (item_id, item_name, item_type, unlocked_at) 
-- VALUES ('boolean_shield', 'The Boolean Shield', 'shield', datetime('now'));
