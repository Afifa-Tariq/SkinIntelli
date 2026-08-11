-- SkinIntelli MySQL Database Schema
-- Complete schema with all tables, relationships, and constraints

CREATE DATABASE IF NOT EXISTS Skinintelli;
USE Skinintelli;

-- ============================================================================
-- TABLE 1: users
-- Master user account table
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 2: user_settings
-- Stores per-user app preferences. One row per user.
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_settings (
    setting_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    notifications_enabled BOOLEAN DEFAULT TRUE,
    preferred_language VARCHAR(10) DEFAULT 'en',
    theme VARCHAR(20) DEFAULT 'light',
    
    CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 3: skin_profiles
-- Stores the user's skin information. One active profile per user at a time.
-- ============================================================================
CREATE TABLE IF NOT EXISTS skin_profiles (
    profile_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    age INT,
    gender VARCHAR(20),
    skin_type ENUM('oily', 'dry', 'combination', 'normal', 'sensitive') NOT NULL,
    sensitivity_level ENUM('low', 'medium', 'high') DEFAULT 'low',
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_skin_profiles_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_is_active (is_active),
    INDEX idx_user_active (user_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 4: user_images
-- Stores uploaded or camera-captured images for a user analysis session.
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_images (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    session_id INT NULL,
    profile_id INT NULL,
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    source VARCHAR(20) NOT NULL DEFAULT 'upload',
    image_bytes LONGBLOB NOT NULL,
    image_size INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_images_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_images_session FOREIGN KEY (session_id)
        REFERENCES skin_analysis_sessions(id) ON DELETE SET NULL,
    CONSTRAINT fk_user_images_profile FOREIGN KEY (profile_id)
        REFERENCES skin_profiles(id) ON DELETE SET NULL,

    INDEX idx_user_images_user_id (user_id),
    INDEX idx_user_images_session_id (session_id),
    INDEX idx_user_images_profile_id (profile_id),
    INDEX idx_user_images_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 5: skin_concerns
-- Normalized multi-value table for user skin concerns.
-- A user can have multiple concerns (acne, eczema, aging, etc.).
-- ============================================================================
CREATE TABLE IF NOT EXISTS skin_concerns (
    concern_id INT PRIMARY KEY AUTO_INCREMENT,
    profile_id INT NOT NULL,
    concern_name VARCHAR(100) NOT NULL,
    
    CONSTRAINT fk_skin_concerns_profile FOREIGN KEY (profile_id) 
        REFERENCES skin_profiles(profile_id) ON DELETE CASCADE,
    
    UNIQUE KEY uk_profile_concern (profile_id, concern_name),
    INDEX idx_profile_id (profile_id),
    INDEX idx_concern_name (concern_name),
    INDEX idx_profile_concern_composite (profile_id, concern_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 5: ingredients
-- The core knowledge base table. Every cosmetic ingredient known to the system.
-- ============================================================================
CREATE TABLE IF NOT EXISTS ingredients (
    ingredient_id INT PRIMARY KEY AUTO_INCREMENT,
    inci_name VARCHAR(255) NOT NULL UNIQUE,
    common_name VARCHAR(255),
    cas_number VARCHAR(50),
    category ENUM('active', 'humectant', 'emollient', 'occlusive', 'preservative', 'surfactant', 'fragrance', 'colorant', 'solvent', 'other') DEFAULT 'other',
    comedogenic_score TINYINT DEFAULT 0,
    irritancy_score TINYINT DEFAULT 0,
    base_safety_score FLOAT DEFAULT 50.0,
    concentration_min FLOAT,
    concentration_max FLOAT,
    cir_approved BOOLEAN DEFAULT FALSE,
    eu_cosing_status ENUM('approved', 'restricted', 'banned', 'unknown') DEFAULT 'unknown',
    source_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_inci_name (inci_name),
    INDEX idx_common_name (common_name),
    INDEX idx_category (category),
    INDEX idx_safety_comedogenic (base_safety_score, comedogenic_score),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 6: ingredient_functions
-- Normalized table for ingredient functions.
-- One ingredient can have multiple functions.
-- ============================================================================
CREATE TABLE IF NOT EXISTS ingredient_functions (
    function_id INT PRIMARY KEY AUTO_INCREMENT,
    ingredient_id INT NOT NULL,
    function_name VARCHAR(100) NOT NULL,
    
    CONSTRAINT fk_ingredient_functions_ingredient FOREIGN KEY (ingredient_id) 
        REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    
    UNIQUE KEY uk_ingredient_function (ingredient_id, function_name),
    INDEX idx_ingredient_id (ingredient_id),
    INDEX idx_function_name (function_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 7: allergy_entries
-- Stores specific ingredient allergies the user has declared.
-- ============================================================================
CREATE TABLE IF NOT EXISTS allergy_entries (
    allergy_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    profile_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    severity ENUM('low', 'medium', 'high') NOT NULL,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_allergy_entries_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_allergy_entries_profile FOREIGN KEY (profile_id) 
        REFERENCES skin_profiles(profile_id) ON DELETE CASCADE,
    CONSTRAINT fk_allergy_entries_ingredient FOREIGN KEY (ingredient_id) 
        REFERENCES ingredients(ingredient_id),
    
    UNIQUE KEY uk_profile_ingredient (profile_id, ingredient_id),
    INDEX idx_user_id (user_id),
    INDEX idx_profile_id (profile_id),
    INDEX idx_ingredient_id (ingredient_id),
    INDEX idx_severity (severity),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 8: ingredient_rules
-- The brain of the recommendation engine.
-- Each row is one rule. Rules are evaluated at runtime against the user's profile.
-- ============================================================================
CREATE TABLE IF NOT EXISTS ingredient_rules (
    rule_id INT PRIMARY KEY AUTO_INCREMENT,
    ingredient_id INT NOT NULL,
    rule_name VARCHAR(255),
    condition_type ENUM('skin_type', 'concern', 'allergy', 'sensitivity', 'age_range') NOT NULL,
    condition_value VARCHAR(100) NOT NULL,
    effect ENUM('BLOCK', 'BOOST', 'WARN', 'ALLOW') NOT NULL,
    effect_magnitude FLOAT DEFAULT 0.0,
    min_concentration FLOAT,
    max_concentration FLOAT,
    priority INT DEFAULT 50,
    evidence_level ENUM('strong', 'moderate', 'anecdotal') DEFAULT 'moderate',
    clinical_source VARCHAR(255),
    source_citation TEXT,
    explanation_template TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_ingredient_rules_ingredient FOREIGN KEY (ingredient_id) 
        REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    
    UNIQUE KEY uk_rule_unique (ingredient_id, condition_type, condition_value),
    INDEX idx_ingredient_id (ingredient_id),
    INDEX idx_ingredient_effect (ingredient_id, effect),
    INDEX idx_irules_condition (condition_type, condition_value),
    INDEX idx_effect (effect),
    INDEX idx_priority (priority),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 9: ingredient_conflicts
-- Stores known chemical or interaction conflicts between pairs of ingredients.
-- ============================================================================
CREATE TABLE IF NOT EXISTS ingredient_conflicts (
    conflict_id INT PRIMARY KEY AUTO_INCREMENT,
    ingredient_a_id INT NOT NULL,
    ingredient_b_id INT NOT NULL,
    conflict_type ENUM('pH_incompatible', 'oxidizes', 'cancels_effect', 'timing_conflict', 'allergic_cross_reaction') NOT NULL,
    severity ENUM('hard_block', 'warning', 'timing_only') NOT NULL,
    explanation TEXT NOT NULL,
    
    CONSTRAINT fk_ingredient_conflicts_a FOREIGN KEY (ingredient_a_id) 
        REFERENCES ingredients(ingredient_id),
    CONSTRAINT fk_ingredient_conflicts_b FOREIGN KEY (ingredient_b_id) 
        REFERENCES ingredients(ingredient_id),
    CONSTRAINT chk_conflict_order CHECK (ingredient_a_id < ingredient_b_id),
    
    UNIQUE KEY uk_conflict_pair (ingredient_a_id, ingredient_b_id),
    INDEX idx_ingredient_a_id (ingredient_a_id),
    INDEX idx_ingredient_b_id (ingredient_b_id),
    INDEX idx_conflict_type (conflict_type),
    INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 10: products
-- Stores cosmetic product catalog
-- ============================================================================
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(255),
    category ENUM('cleanser', 'toner', 'serum', 'moisturizer', 'sunscreen', 'exfoliant', 'mask', 'eye_cream', 'oil', 'other') NOT NULL,
    description TEXT,
    image_url TEXT,
    usage_time ENUM('AM', 'PM', 'both') DEFAULT 'both',
    average_rating FLOAT DEFAULT 0.0,
    base_score FLOAT DEFAULT 50.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_brand (brand),
    INDEX idx_category (category),
    INDEX idx_base_score (base_score),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 11: product_ingredients
-- Junction table linking products to their ingredients
-- ============================================================================
CREATE TABLE IF NOT EXISTS product_ingredients (
    pi_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    position INT,
    concentration FLOAT,
    
    CONSTRAINT fk_product_ingredients_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_product_ingredients_ingredient FOREIGN KEY (ingredient_id) 
        REFERENCES ingredients(ingredient_id),
    
    UNIQUE KEY uk_product_ingredient (product_id, ingredient_id),
    INDEX idx_product_id (product_id),
    INDEX idx_ingredient_id (ingredient_id),
    INDEX idx_position (position),
    INDEX idx_concentration (concentration)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 12: routines
-- A named skincare routine belonging to a user
-- ============================================================================
CREATE TABLE IF NOT EXISTS routines (
    routine_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_routines_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    INDEX idx_routine_user_active (user_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 13: routine_items
-- Each product step inside a routine with scheduling info
-- ============================================================================
CREATE TABLE IF NOT EXISTS routine_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    routine_id INT NOT NULL,
    product_id INT NOT NULL,
    time_of_day ENUM('AM', 'PM', 'both') NOT NULL,
    step_order INT NOT NULL,
    notes TEXT,
    
    CONSTRAINT fk_routine_items_routine FOREIGN KEY (routine_id) 
        REFERENCES routines(routine_id) ON DELETE CASCADE,
    CONSTRAINT fk_routine_items_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id),
    
    UNIQUE KEY uk_routine_product_time (routine_id, product_id, time_of_day),
    INDEX idx_routine_id (routine_id),
    INDEX idx_product_id (product_id),
    INDEX idx_step_order (step_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 14: recommendation_records
-- Stores the history of each recommendation session generated for a user
-- ============================================================================
CREATE TABLE IF NOT EXISTS recommendation_records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    profile_id INT NOT NULL,
    generated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    filter_used VARCHAR(255),
    total_products_evaluated INT,
    
    CONSTRAINT fk_recommendation_records_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_recommendation_records_profile FOREIGN KEY (profile_id) 
        REFERENCES skin_profiles(profile_id),
    
    INDEX idx_user_id (user_id),
    INDEX idx_profile_id (profile_id),
    INDEX idx_generated_at (generated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 15: recommendation_products
-- Each product result within a recommendation session
-- ============================================================================
CREATE TABLE IF NOT EXISTS recommendation_products (
    rp_id INT PRIMARY KEY AUTO_INCREMENT,
    record_id INT NOT NULL,
    product_id INT NOT NULL,
    final_score FLOAT NOT NULL,
    is_blocked BOOLEAN DEFAULT FALSE,
    block_reason TEXT,
    boost_summary TEXT,
    warning_summary TEXT,
    allergy_flags TEXT,
    explanation TEXT,
    `rank` INT,
    
    CONSTRAINT fk_recommendation_products_record FOREIGN KEY (record_id) 
        REFERENCES recommendation_records(record_id) ON DELETE CASCADE,
    CONSTRAINT fk_recommendation_products_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id),
    
    INDEX idx_record_id (record_id),
    INDEX idx_product_id (product_id),
    INDEX idx_final_score (final_score),
    INDEX idx_is_blocked (is_blocked),
    INDEX idx_rank (`rank`),
    INDEX idx_recommendation_score_rank (record_id, final_score, `rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE 16: feedback_entries
-- User ratings and comments on products from recommendation results
-- ============================================================================
CREATE TABLE IF NOT EXISTS feedback_entries (
    feedback_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    record_id INT,
    rating TINYINT,
    comment TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_feedback_entries_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_feedback_entries_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id),
    CONSTRAINT fk_feedback_entries_record FOREIGN KEY (record_id) 
        REFERENCES recommendation_records(record_id),
    
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id),
    INDEX idx_record_id (record_id),
    INDEX idx_rating (rating),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Confirmation message
SELECT 'SkinIntelli full schema created or verified.' AS status;
