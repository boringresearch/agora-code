#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BUILD_ROOT = PROJECT_ROOT / "build" / "web"
SOURCE_WEB_ROOT = PROJECT_ROOT / "web"
PORT = int(os.environ.get("PORT", "39865"))


class NoCacheHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD_ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def translate_path(self, path):
        build_path = Path(super().translate_path(path))
        if build_path.exists():
            return str(build_path)

        relative = build_path.relative_to(BUILD_ROOT)
        source_path = (SOURCE_WEB_ROOT / relative).resolve()
        if source_path.is_relative_to(SOURCE_WEB_ROOT) and source_path.exists():
            return str(source_path)

        return str(build_path)


if __name__ == "__main__":
    if not BUILD_ROOT.exists():
        raise SystemExit(f"Missing {BUILD_ROOT}. Run `flutter build web` first.")
    server = ThreadingHTTPServer(("0.0.0.0", PORT), NoCacheHandler)
    print(f"Serving {BUILD_ROOT} at http://0.0.0.0:{PORT}/")
    print(f"Falling back to {SOURCE_WEB_ROOT} for extra static files.")
    server.serve_forever()
