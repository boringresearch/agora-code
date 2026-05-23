#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib import error as urlerror
from urllib import request
import json
import os


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BUILD_ROOT = PROJECT_ROOT / "build" / "web"
SOURCE_WEB_ROOT = PROJECT_ROOT / "web"
PORT = int(os.environ.get("PORT", "39865"))
LLM_PROXY_PREFIX = "/api/llm"
LLM_PROXY_TARGET = os.environ.get("LLM_PROXY_TARGET", "https://gw2.oops.asia/v1").rstrip("/")


class NoCacheHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD_ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def do_OPTIONS(self):
        if self.path.startswith(LLM_PROXY_PREFIX):
            self.send_response(204)
            self._send_cors_headers()
            self.end_headers()
            return
        super().do_OPTIONS()

    def do_POST(self):
        if self.path.startswith(LLM_PROXY_PREFIX):
            self._proxy_llm_post()
            return
        self.send_error(404, "Not found")

    def _proxy_llm_post(self):
        suffix = self.path[len(LLM_PROXY_PREFIX):]
        if not suffix.startswith("/"):
            suffix = "/" + suffix
        target = f"{LLM_PROXY_TARGET}{suffix}"
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length)
        is_stream = self._is_streaming_request(body)
        headers = {
            "Content-Type": self.headers.get("Content-Type", "application/json"),
            "User-Agent": self.headers.get("User-Agent", "curl/8.5.0"),
            "Accept": "text/event-stream" if is_stream else self.headers.get("Accept", "application/json"),
        }
        authorization = self.headers.get("Authorization")
        if authorization:
            headers["Authorization"] = authorization
        try:
            upstream = request.Request(target, data=body, headers=headers, method="POST")
            with request.urlopen(upstream, timeout=90) as response:
                self.send_response(response.status)
                self._send_cors_headers()
                self.send_header("Content-Type", response.headers.get("Content-Type", "application/json"))
                if is_stream:
                    self.send_header("X-Accel-Buffering", "no")
                    self.end_headers()
                    while True:
                        chunk = response.readline()
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                        self.wfile.flush()
                else:
                    payload = response.read()
                    self.send_header("Content-Length", str(len(payload)))
                    self.end_headers()
                    self.wfile.write(payload)
        except urlerror.HTTPError as exc:
            payload = exc.read()
            self.send_response(exc.code)
            self._send_cors_headers()
            self.send_header("Content-Type", exc.headers.get("Content-Type", "application/json"))
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        except Exception as exc:
            payload = f'{{"error":"LLM proxy failed: {str(exc)}"}}'.encode("utf-8")
            self.send_response(502)
            self._send_cors_headers()
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

    def _is_streaming_request(self, body):
        try:
            payload = json.loads(body.decode("utf-8"))
        except Exception:
            return False
        return isinstance(payload, dict) and payload.get("stream") is True

    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")

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
    print(f"Proxying {LLM_PROXY_PREFIX}/* to {LLM_PROXY_TARGET}/*")
    server.serve_forever()
