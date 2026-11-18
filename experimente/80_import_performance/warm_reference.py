"""HTTP transport for the external CPython baseline. The purchase contract stays in the reference."""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import sqlite3
import sys

from reference import decode_document, import_document


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        raw = self.rfile.read(int(self.headers["Content-Length"]))
        db = sqlite3.connect(sys.argv[1], timeout=0)
        try:
            receipt = import_document(db, decode_document(raw))
        finally:
            db.close()
        data = json.dumps(receipt, separators=(",", ":")).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_):
        pass


with HTTPServer(("127.0.0.1", 0), Handler) as server:
    print(f"LISTEN 127.0.0.1:{server.server_port}", file=sys.stderr, flush=True)
    server.serve_forever()
