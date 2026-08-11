import pymysql

conn = pymysql.connect(host="127.0.0.1", user="root", password="Zarsh24.", db="Skinintelli")
with conn.cursor() as cur:
    cur.execute(
        "SELECT rule_id, ingredient_id, rule_name, condition_type, condition_value, effect, "
        "evidence_level, clinical_source, source_citation, explanation_template FROM ingredient_rules LIMIT 6"
    )
    print("ingredient_rules sample:")
    for r in cur.fetchall():
        print(" ", r)

    print()
    cur.execute(
        "SELECT ingredient_id, inci_name, common_name, category, comedogenic_score, irritancy_score, "
        "base_safety_score, cir_approved, eu_cosing_status FROM ingredients LIMIT 6"
    )
    print("ingredients sample:")
    for r in cur.fetchall():
        print(" ", r)

    print()
    cur.execute("SELECT ingredient_id, function_name FROM ingredient_functions LIMIT 10")
    print("ingredient_functions sample:")
    for r in cur.fetchall():
        print(" ", r)

    print()
    cur.execute("SELECT COUNT(*) FROM ingredient_rules WHERE explanation_template IS NOT NULL AND explanation_template != ''")
    print("rules with explanation_template:", cur.fetchone()[0], "/ 68 total")
    cur.execute("SELECT COUNT(*) FROM ingredient_rules WHERE clinical_source IS NOT NULL AND clinical_source != ''")
    print("rules with clinical_source:", cur.fetchone()[0])
    cur.execute("SELECT COUNT(*) FROM ingredient_rules WHERE source_citation IS NOT NULL AND source_citation != ''")
    print("rules with source_citation:", cur.fetchone()[0])
    cur.execute("SELECT DISTINCT function_name FROM ingredient_functions")
    print("distinct function_names:", [r[0] for r in cur.fetchall()])
conn.close()
