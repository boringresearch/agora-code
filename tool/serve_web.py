#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os


ROOT = Path(__file__).resolve().parents[1] / "build" / "web"
PORT = int(os.environ.get("PORT", "39865"))


class NoCacheHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


if __name__ == "__main__":
    if not ROOT.exists():
        raise SystemExit(f"Missing {ROOT}. Run `flutter build web` first.")
    server = ThreadingHTTPServer(("0.0.0.0", PORT), NoCacheHandler)
    print(f"Serving {ROOT} at http://0.0.0.0:{PORT}/")
    server.serve_forever()
