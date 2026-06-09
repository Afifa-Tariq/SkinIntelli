"""
╔══════════════════════════════════════════════════════════════════╗
║         SkinIntelli — Safe MySQL Migration Script               ║
║                                                                  ║
║  ✅ Reads your database credentials from backend/.env             ║
║  ✅ Creates the Skinintelli database if it does not exist         ║
║  ✅ Creates missing tables only                                    ║
║  ✅ SKIPS tables that already exist — zero changes to them         ║
║  ✅ Creates indexes safely (skips existing ones)                  ║
║  ✅ Safe to re-run multiple times                                 ║
║                                                                  ║
║  HOW TO RUN:                                                     ║
║    1. pip install -r requirements.txt                            ║
║    2. python skinintelli_migrate.py                              ║
╚══════════════════════════════════════════════════════════════════╝
"""

import os
import sys
import re
import pymysql
from dotenv import load_dotenv
from urllib.parse import urlparse, unquote

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))

DATABASE_URL = os.environ.get("DATABASE_URL", "")
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_USER = os.environ.get("DB_USER", os.environ.get("MYSQL_USER", "root"))
DB_PASSWORD = os.environ.get("DB_PASSWORD", os.environ.get("MYSQL_PASSWORD", ""))
DB_NAME = os.environ.get("DB_NAME", os.environ.get("DATABASE_NAME", "Skinintelli"))

# If DATABASE_URL is provided, parse it into connection parts.
if DATABASE_URL:
    parsed = urlparse(DATABASE_URL)
    if parsed.scheme.startswith("mysql"):
        DB_HOST = parsed.hostname or DB_HOST
        DB_PORT = parsed.port or DB_PORT
        DB_USER = parsed.username or DB_USER
        DB_PASSWORD = unquote(parsed.password) if parsed.password else DB_PASSWORD
        DB_NAME = parsed.path.lstrip("/") or DB_NAME

TABLES = [
    ("users", """
CREATE TABLE IF NOT EXISTS `users` (
    `user_id`       INT           NOT NULL AUTO_INCREMENT,
    `email`         VARCHAR(255)  NOT NULL,
    `password_hash` VARCHAR(255)  NOT NULL,
    `created_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `is_active`     BOOLEAN       NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Master user account table';
"""),
    ("user_settings", """
CREATE TABLE IF NOT EXISTS `user_settings` (
    `setting_id`            INT         NOT NULL AUTO_INCREMENT,
    `user_id`               INT         NOT NULL,
    `notifications_enabled` BOOLEAN     NOT NULL DEFAULT TRUE,
    `preferred_language`    VARCHAR(10) NOT NULL DEFAULT 'en',
    `theme`                 VARCHAR(20) NOT NULL DEFAULT 'light',
    PRIMARY KEY (`setting_id`),
    UNIQUE KEY `uq_user_settings_user` (`user_id`),
    CONSTRAINT `fk_usettings_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-user app preferences, one row per user';
"""),
    ("skin_profiles", """
CREATE TABLE IF NOT EXISTS `skin_profiles` (
    `profile_id`        INT      NOT NULL AUTO_INCREMENT,
    `user_id`           INT      NOT NULL,
    `age`               INT,
    `gender`            VARCHAR(20),
    `skin_type`         ENUM('oily','dry','combination','normal','sensitive') NOT NULL,
    `sensitivity_level` ENUM('low','medium','high') NOT NULL DEFAULT 'low',
    `is_active`         BOOLEAN  NOT NULL DEFAULT TRUE,
    `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`profile_id`),
    CONSTRAINT `fk_sprofile_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='User skin information, one active profile per user at a time';
"""),
    ("ingredients", """
CREATE TABLE IF NOT EXISTS `ingredients` (
    `ingredient_id`     INT          NOT NULL AUTO_INCREMENT,
    `inci_name`         VARCHAR(255) NOT NULL COMMENT 'Official INCI name e.g. Salicylic Acid',
    `common_name`       VARCHAR(255)          COMMENT 'Common name e.g. Vitamin C',
    `cas_number`        VARCHAR(50)           COMMENT 'Chemical Abstracts Service identifier',
    `category`          ENUM('active','humectant','emollient','occlusive','preservative',
                             'surfactant','fragrance','colorant','solvent','other')
                                     NOT NULL DEFAULT 'other',
    `comedogenic_score` TINYINT      NOT NULL DEFAULT 0 COMMENT 'Scale 0-5',
    `irritancy_score`   TINYINT      NOT NULL DEFAULT 0 COMMENT 'Scale 0-5',
    `base_safety_score` FLOAT        NOT NULL DEFAULT 50.0 COMMENT 'Precomputed score 0-100',
    `concentration_min` FLOAT                 COMMENT 'Minimum safe concentration as percentage',
    `concentration_max` FLOAT                 COMMENT 'Maximum safe concentration as percentage',
    `cir_approved`      BOOLEAN      NOT NULL DEFAULT FALSE,
    `eu_cosing_status`  ENUM('approved','restricted','banned','unknown') NOT NULL DEFAULT 'unknown',
    `source_url`        TEXT                  COMMENT 'Link to CIR monograph or clinical source',
    `created_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`ingredient_id`),
    UNIQUE KEY `uq_ingredients_inci` (`inci_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Core ingredient knowledge base sourced from CIR and EU CosIng';
"""),
    ("skin_concerns", """
CREATE TABLE IF NOT EXISTS `skin_concerns` (
    `concern_id`   INT          NOT NULL AUTO_INCREMENT,
    `profile_id`   INT          NOT NULL,
    `concern_name` VARCHAR(100) NOT NULL COMMENT 'e.g. acne, eczema, aging, hyperpigmentation, rosacea',
    PRIMARY KEY (`concern_id`),
    UNIQUE KEY `uq_concern_profile` (`profile_id`, `concern_name`),
    CONSTRAINT `fk_sconcern_profile`
        FOREIGN KEY (`profile_id`) REFERENCES `skin_profiles`(`profile_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Normalized multi-value skin concerns per profile';
"""),
    ("allergy_entries", """
CREATE TABLE IF NOT EXISTS `allergy_entries` (
    `allergy_id`    INT      NOT NULL AUTO_INCREMENT,
    `user_id`       INT      NOT NULL,
    `profile_id`    INT      NOT NULL,
    `ingredient_id` INT      NOT NULL,
    `severity`      ENUM('low','medium','high') NOT NULL,
    `notes`         TEXT,
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`allergy_id`),
    UNIQUE KEY `uq_allergy_profile_ingredient` (`profile_id`, `ingredient_id`),
    CONSTRAINT `fk_allergy_user`
        FOREIGN KEY (`user_id`)       REFERENCES `users`(`user_id`)       ON DELETE CASCADE,
    CONSTRAINT `fk_allergy_profile`
        FOREIGN KEY (`profile_id`)    REFERENCES `skin_profiles`(`profile_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_allergy_ingredient`
        FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`ingredient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ingredient allergies declared by the user with severity level';
"""),
    ("ingredient_functions", """
CREATE TABLE IF NOT EXISTS `ingredient_functions` (
    `function_id`   INT          NOT NULL AUTO_INCREMENT,
    `ingredient_id` INT          NOT NULL,
    `function_name` VARCHAR(100) NOT NULL COMMENT 'e.g. exfoliant, anti-inflammatory, moisturizing',
    PRIMARY KEY (`function_id`),
    UNIQUE KEY `uq_ingfunc` (`ingredient_id`, `function_name`),
    CONSTRAINT `fk_ifunc_ingredient`
        FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`ingredient_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Normalized ingredient functions, replaces list columns';
"""),
    ("ingredient_rules", """
CREATE TABLE IF NOT EXISTS `ingredient_rules` (
    `rule_id`              INT          NOT NULL AUTO_INCREMENT,
    `ingredient_id`        INT          NOT NULL,
    `rule_name`            VARCHAR(255)          COMMENT 'Human label e.g. Salicylic Acid blocks eczema',
    `condition_type`       ENUM('skin_type','concern','allergy','sensitivity','age_range')
                                        NOT NULL COMMENT 'Which profile aspect this rule checks',
    `condition_value`      VARCHAR(100) NOT NULL COMMENT 'Value to match e.g. acne, oily, eczema',
    `effect`               ENUM('BLOCK','BOOST','WARN','ALLOW') NOT NULL,
    `effect_magnitude`     FLOAT        NOT NULL DEFAULT 0.0
                           COMMENT '+30 for BOOST, -20 for WARN, -100 for BLOCK',
    `min_concentration`    FLOAT        DEFAULT NULL COMMENT 'Rule fires only above this % conc',
    `max_concentration`    FLOAT        DEFAULT NULL COMMENT 'Rule fires only below this % conc',
    `priority`             INT          NOT NULL DEFAULT 50
                           COMMENT 'Higher = evaluated first. BLOCK=100, BOOST=50',
    `evidence_level`       ENUM('strong','moderate','anecdotal') NOT NULL DEFAULT 'moderate',
    `clinical_source`      VARCHAR(255) COMMENT 'e.g. CIR_2023, PubMed_PMID_12345',
    `source_citation`      TEXT         COMMENT 'Full citation text from the source',
    `explanation_template` TEXT         COMMENT 'Template: Blocked because {ingredient_name} irritates {condition_value} skin',
    `created_at`           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`rule_id`),
    CONSTRAINT `fk_irule_ingredient`
        FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`ingredient_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Rule engine knowledge base — each row is one evaluatable rule. No rules in Python code.';
"""),
    ("ingredient_conflicts", """
CREATE TABLE IF NOT EXISTS `ingredient_conflicts` (
    `conflict_id`     INT  NOT NULL AUTO_INCREMENT,
    `ingredient_a_id` INT  NOT NULL,
    `ingredient_b_id` INT  NOT NULL,
    `conflict_type`   ENUM('pH_incompatible','oxidizes','cancels_effect','timing_conflict','allergic_cross_reaction') NOT NULL,
    `severity`        ENUM('hard_block','warning','timing_only') NOT NULL,
    `explanation`     TEXT NOT NULL COMMENT 'Human-readable explanation shown to user',
    PRIMARY KEY (`conflict_id`),
    UNIQUE KEY `uq_conflict_pair` (`ingredient_a_id`, `ingredient_b_id`),
    CONSTRAINT `fk_conflict_a`
        FOREIGN KEY (`ingredient_a_id`) REFERENCES `ingredients`(`ingredient_id`),
    CONSTRAINT `fk_conflict_b`
        FOREIGN KEY (`ingredient_b_id`) REFERENCES `ingredients`(`ingredient_id`),
    CONSTRAINT `chk_conflict_order` CHECK (`ingredient_a_id` < `ingredient_b_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Known chemical or interaction conflicts between ingredient pairs';
"""),
    ("products", """
CREATE TABLE IF NOT EXISTS `products` (
    `product_id`     INT          NOT NULL AUTO_INCREMENT,
    `name`           VARCHAR(255) NOT NULL,
    `brand`          VARCHAR(255),
    `category`       ENUM('cleanser','toner','serum','moisturizer','sunscreen','exfoliant','mask','eye_cream','oil','other') NOT NULL,
    `description`    TEXT,
    `image_url`      TEXT,
    `usage_time`     ENUM('AM','PM','both') NOT NULL DEFAULT 'both',
    `average_rating` FLOAT        NOT NULL DEFAULT 0.0,
    `base_score`     FLOAT        NOT NULL DEFAULT 50.0 COMMENT 'Precomputed aggregate safety score, updated by admin job',
    `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Cosmetic product catalog';
"""),
    ("product_ingredients", """
CREATE TABLE IF NOT EXISTS `product_ingredients` (
    `pi_id`         INT   NOT NULL AUTO_INCREMENT,
    `product_id`    INT   NOT NULL,
    `ingredient_id` INT   NOT NULL,
    `position`      INT            COMMENT 'Position in INCI list, 1 = highest concentration',
    `concentration` FLOAT DEFAULT NULL COMMENT 'Exact percentage if known, NULL if unknown',
    PRIMARY KEY (`pi_id`),
    UNIQUE KEY `uq_product_ingredient` (`product_id`, `ingredient_id`),
    CONSTRAINT `fk_pi_product`
        FOREIGN KEY (`product_id`)    REFERENCES `products`(`product_id`)     ON DELETE CASCADE,
    CONSTRAINT `fk_pi_ingredient`
        FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`ingredient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Junction table linking products to their full ingredient lists';
"""),
    ("routines", """
CREATE TABLE IF NOT EXISTS `routines` (
    `routine_id` INT          NOT NULL AUTO_INCREMENT,
    `user_id`    INT          NOT NULL,
    `name`       VARCHAR(255) NOT NULL,
    `is_active`  BOOLEAN      NOT NULL DEFAULT TRUE,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`routine_id`),
    CONSTRAINT `fk_routine_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Named skincare routine belonging to a user';
"""),
    ("routine_items", """
CREATE TABLE IF NOT EXISTS `routine_items` (
    `item_id`     INT  NOT NULL AUTO_INCREMENT,
    `routine_id`  INT  NOT NULL,
    `product_id`  INT  NOT NULL,
    `time_of_day` ENUM('AM','PM','both') NOT NULL,
    `step_order`  INT  NOT NULL COMMENT 'Application order e.g. 1=cleanser, 2=toner',
    `notes`       TEXT,
    PRIMARY KEY (`item_id`),
    UNIQUE KEY `uq_routine_product_time` (`routine_id`, `product_id`, `time_of_day`),
    CONSTRAINT `fk_ritem_routine`
        FOREIGN KEY (`routine_id`) REFERENCES `routines`(`routine_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ritem_product`
        FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Individual product steps inside a routine with AM/PM scheduling';
"""),
    ("recommendation_records", """
CREATE TABLE IF NOT EXISTS `recommendation_records` (
    `record_id`                INT          NOT NULL AUTO_INCREMENT,
    `user_id`                  INT          NOT NULL,
    `profile_id`               INT          NOT NULL,
    `generated_at`             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `filter_used`              VARCHAR(255) COMMENT 'Category filter applied e.g. moisturizer',
    `total_products_evaluated` INT,
    PRIMARY KEY (`record_id`),
    CONSTRAINT `fk_rec_user`
        FOREIGN KEY (`user_id`)    REFERENCES `users`(`user_id`)        ON DELETE CASCADE,
    CONSTRAINT `fk_rec_profile`
        FOREIGN KEY (`profile_id`) REFERENCES `skin_profiles`(`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Header record for each recommendation engine session';
"""),
    ("recommendation_products", """
CREATE TABLE IF NOT EXISTS `recommendation_products` (
    `rp_id`           INT     NOT NULL AUTO_INCREMENT,
    `record_id`       INT     NOT NULL,
    `product_id`      INT     NOT NULL,
    `final_score`     FLOAT   NOT NULL COMMENT 'Computed score 0-100 after all rules applied',
    `is_blocked`      BOOLEAN NOT NULL DEFAULT FALSE,
    `block_reason`    TEXT             COMMENT 'Populated when is_blocked = TRUE',
    `boost_summary`   TEXT             COMMENT 'Summary of all BOOST rules that fired',
    `warning_summary` TEXT             COMMENT 'Summary of all WARN rules that fired',
    `allergy_flags`   TEXT             COMMENT 'Comma-separated allergen ingredient names found',
    `explanation`     TEXT             COMMENT 'Full natural language explanation shown to user',
    `rank`            INT              COMMENT 'Final position in the ranked recommendation list',
    PRIMARY KEY (`rp_id`),
    CONSTRAINT `fk_rp_record`
        FOREIGN KEY (`record_id`)  REFERENCES `recommendation_records`(`record_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rp_product`
        FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Each product scored and ranked within a recommendation session';
"""),
    ("feedback_entries", """
CREATE TABLE IF NOT EXISTS `feedback_entries` (
    `feedback_id` INT      NOT NULL AUTO_INCREMENT,
    `user_id`     INT      NOT NULL,
    `product_id`  INT      NOT NULL,
    `record_id`   INT      DEFAULT NULL COMMENT 'Which recommendation session this feedback came from',
    `rating`      TINYINT           COMMENT '1 to 5 stars',
    `comment`     TEXT,
    `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`feedback_id`),
    CONSTRAINT `fk_fb_user`
        FOREIGN KEY (`user_id`)    REFERENCES `users`(`user_id`)    ON DELETE CASCADE,
    CONSTRAINT `fk_fb_product`
        FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`),
    CONSTRAINT `fk_fb_record`
        FOREIGN KEY (`record_id`)  REFERENCES `recommendation_records`(`record_id`) ON DELETE SET NULL,
    CONSTRAINT `chk_rating` CHECK (`rating` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='User ratings and comments on recommended products';
"""),
    ("activity_logs", """
CREATE TABLE IF NOT EXISTS `activity_logs` (
    `log_id`     INT          NOT NULL AUTO_INCREMENT,
    `user_id`    INT          DEFAULT NULL,
    `action`     VARCHAR(100) NOT NULL COMMENT 'e.g. login, generate_recommendation, add_allergy',
    `detail`     TEXT                  COMMENT 'JSON string with additional context',
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`log_id`),
    CONSTRAINT `fk_log_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='System-level activity logging for admin analytics dashboard';
"""),
]

INDEXES = [
    ("idx_irules_ingredient", "CREATE INDEX `idx_irules_ingredient` ON `ingredient_rules`(`ingredient_id`);"),
    ("idx_irules_condition", "CREATE INDEX `idx_irules_condition` ON `ingredient_rules`(`condition_type`, `condition_value`);"),
    ("idx_irules_priority", "CREATE INDEX `idx_irules_priority` ON `ingredient_rules`(`priority`);"),
    ("idx_pi_product", "CREATE INDEX `idx_pi_product` ON `product_ingredients`(`product_id`);"),
    ("idx_pi_ingredient", "CREATE INDEX `idx_pi_ingredient` ON `product_ingredients`(`ingredient_id`);"),
    ("idx_rec_user", "CREATE INDEX `idx_rec_user` ON `recommendation_records`(`user_id`);"),
    ("idx_fb_product", "CREATE INDEX `idx_fb_product` ON `feedback_entries`(`product_id`);"),
    ("idx_skin_concerns_profile", "CREATE INDEX `idx_skin_concerns_profile` ON `skin_concerns`(`profile_id`);"),
    ("idx_allergy_profile", "CREATE INDEX `idx_allergy_profile` ON `allergy_entries`(`profile_id`);"),
    ("idx_log_user", "CREATE INDEX `idx_log_user` ON `activity_logs`(`user_id`);")
]


def get_existing_tables(cursor, db_name):
    cursor.execute(
        "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = %s;",
        (db_name,)
    )
    return {row[0].lower() for row in cursor.fetchall()}


def get_existing_indexes(cursor, db_name):
    cursor.execute(
        "SELECT DISTINCT INDEX_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = %s;",
        (db_name,)
    )
    return {row[0].lower() for row in cursor.fetchall()}


def run_migration():
    print("\n" + "=" * 62)
    print("  SkinIntelli — MySQL Safe Migration")
    print(f"  Database : {DB_NAME}")
    print(f"  Host     : {DB_HOST}:{DB_PORT}")
    print("=" * 62 + "\n")

    if not DB_PASSWORD and not DATABASE_URL:
        print("  ERROR: Database password is missing.")
        print("  Add DB_PASSWORD to backend/.env or set a valid DATABASE_URL.")
        sys.exit(1)

    try:
        conn = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            charset="utf8mb4",
            autocommit=True,
        )
        cursor = conn.cursor()
        cursor.execute(
            f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        )
        cursor.execute(f"USE `{DB_NAME}`;")
        print("  Connected to MySQL and selected database successfully\n")
    except Exception as e:
        print(f"  Connection FAILED: {e}")
        print("\n  Make sure:")
        print("  - MySQL Server is running")
        print("  - backend/.env contains valid credentials")
        print("  - the database host, port, user, and password are correct")
        sys.exit(1)

    existing_tables = get_existing_tables(cursor, DB_NAME)
    existing_indexes = get_existing_indexes(cursor, DB_NAME)

    print(f"  Found {len(existing_tables)} existing table(s) — will NOT be modified:")
    for table_name in sorted(existing_tables):
        print(f"    -> {table_name}")
    print()

    created, skipped, failed = [], [], []
    print("  Creating Tables")
    print("  " + "-" * 58)
    for table_name, table_sql in TABLES:
        if table_name.lower() in existing_tables:
            skipped.append(table_name)
            print(f"  SKIP    {table_name:<35} (already exists)")
            continue
        try:
            cursor.execute(table_sql)
            created.append(table_name)
            print(f"  CREATED {table_name}")
        except Exception as exc:
            failed.append((table_name, str(exc)))
            print(f"  FAILED  {table_name}")
            print(f"          {exc}")

    print()
    print("  Creating Indexes")
    print("  " + "-" * 58)
    idx_created, idx_skipped, idx_failed = [], [], []
    for idx_name, idx_sql in INDEXES:
        if idx_name.lower() in existing_indexes:
            idx_skipped.append(idx_name)
            print(f"  SKIP INDEX  {idx_name:<40} (exists)")
            continue
        try:
            cursor.execute(idx_sql)
            idx_created.append(idx_name)
            print(f"  INDEX       {idx_name}")
        except Exception as exc:
            idx_failed.append((idx_name, str(exc)))
            print(f"  FAILED INDEX {idx_name}")
            print(f"              {exc}")

    print()
    print("=" * 62)
    print("  SUMMARY")
    print("=" * 62)
    print(f"  Tables  created  : {len(created)}")
    print(f"  Tables  skipped  : {len(skipped)}")
    print(f"  Tables  failed   : {len(failed)}")
    print(f"  Indexes created  : {len(idx_created)}")
    print(f"  Indexes skipped  : {len(idx_skipped)}")
    print(f"  Indexes failed   : {len(idx_failed)}")

    if created:
        print("\n  New tables added:")
        for name in created:
            print(f"    + {name}")
    if failed:
        print("\n  Failed tables:")
        for name, err in failed:
            print(f"    x {name}: {err}")
    if idx_failed:
        print("\n  Failed indexes:")
        for name, err in idx_failed:
            print(f"    x {name}: {err}")

    if not failed and not idx_failed:
        print("\n  Migration completed successfully. Existing tables were not modified.")

    cursor.close()
    conn.close()


if __name__ == "__main__":
    run_migration()
