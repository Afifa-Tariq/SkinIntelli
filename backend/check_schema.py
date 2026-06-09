import pymysql

conn = pymysql.connect(host='127.0.0.1', user='root', password='Zarsh24.', db='Skinintelli')
with conn.cursor() as cur:
    tables = ['users', 'token_blocklist', 'skin_profiles']
    print('SCHEMA')
    for tbl in tables:
        print('TABLE', tbl)
        cur.execute(
            "SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY, EXTRA "
            "FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s "
            "ORDER BY ORDINAL_POSITION",
            ('Skinintelli', tbl),
        )
        rows = cur.fetchall()
        if not rows:
            print('  MISSING')
        for r in rows:
            print(' ', r)
        print()
conn.close()
