#!/usr/bin/env python3
import os, sys, json, urllib.parse, subprocess
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

CATALOG_HOST = os.environ.get("CATALOG_HOST", "127.0.0.1")
CATALOG_PORT = os.environ.get("CATALOG_PORT", "5432")
CATALOG_USER = os.environ.get("CATALOG_USER", "grafana_reader")
CATALOG_PASS = os.environ.get("CATALOG_PASS", "1")
CATALOG_DB   = os.environ.get("CATALOG_DB", "monitoring_catalog")
PORT         = int(os.environ.get("PORT", "8088"))

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PUBLIC_DIR = os.path.join(BASE_DIR, "public")

def run_psql(sql):
    env = os.environ.copy()
    if CATALOG_PASS:
        env["PGPASSWORD"] = CATALOG_PASS

    hosts = [CATALOG_HOST]
    if CATALOG_HOST != "127.0.0.1":
        hosts.append("127.0.0.1")
    if CATALOG_HOST != "192.168.1.53":
        hosts.append("192.168.1.53")

    for h in hosts:
        cmd = [
            "psql", "-U", CATALOG_USER, "-h", h, "-p", str(CATALOG_PORT), "-d", CATALOG_DB,
            "-t", "-A", "-F", "\t", "-c", sql
        ]
        try:
            out = subprocess.check_output(cmd, env=env, stderr=subprocess.PIPE).decode("utf-8").strip()
            return out.split("\n")
        except Exception:
            continue
    return []

def query_catalog(device, db):
    # Query tables
    sql_tables = f"""
    SELECT schema_name, table_name, column_count, columns_detail
    FROM db_metadata_tables
    WHERE device = '{device}' AND ('{db}' = 'All' OR '{db}' = '' OR database_name = '{db}');
    """
    tables = []
    out_t = run_psql(sql_tables)
    for line in out_t:
        if not line: continue
        parts = line.split("\t")
        if len(parts) >= 4:
            tables.append({
                "schema_name": parts[0],
                "table_name": parts[1],
                "column_count": int(parts[2]),
                "columns_detail": parts[3]
            })

    # Query relations
    sql_rels = f"""
    SELECT schema_name, constraint_name, from_table, from_column, to_table, to_column, cardinality
    FROM db_metadata_relations
    WHERE device = '{device}' AND ('{db}' = 'All' OR '{db}' = '' OR database_name = '{db}');
    """
    relations = []
    out_r = run_psql(sql_rels)
    for line in out_r:
        if not line: continue
        parts = line.split("\t")
        if len(parts) >= 7:
            relations.append({
                "schema_name": parts[0],
                "constraint_name": parts[1],
                "from_table": parts[2],
                "from_column": parts[3],
                "to_table": parts[4],
                "to_column": parts[5],
                "cardinality": parts[6]
            })

    return {"device": device, "db": db, "tables": tables, "relations": relations}

class ERDHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=PUBLIC_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/erd":
            params = urllib.parse.parse_qs(parsed.query)
            device = params.get("device", ["cuonglq"])[0]
            db = params.get("db", ["erd_demo"])[0]

            data = query_catalog(device, db)
            body = json.dumps(data).encode("utf-8")

            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        super().do_GET()

def main():
    server_address = ("0.0.0.0", PORT)
    httpd = ThreadingHTTPServer(server_address, ERDHandler)
    print(f" ERD Cytoscape Viewer Service running at http://0.0.0.0:{PORT} (Serving: {PUBLIC_DIR})")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping ERD Server...")
        httpd.server_close()

if __name__ == "__main__":
    main()
