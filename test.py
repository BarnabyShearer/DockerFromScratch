import psycopg2

def application(env, start_response):
    start_response('200 OK', [('Content-Type','text/html')])
    conn = psycopg2.connect('')
    with conn.cursor() as cur:
        cur.execute("SELECT 'Hello World'")
        return [cur.fetchone()[0].encode()]
