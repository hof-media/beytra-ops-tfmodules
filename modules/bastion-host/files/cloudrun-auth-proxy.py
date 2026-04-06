#!/usr/bin/env python3
"""
Cloud Run Authentication Proxy.
Forwards local HTTP to a Cloud Run service, injecting an identity token
minted from the VM's metadata service.
"""

import logging
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

import requests

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s: %(message)s")


class CloudRunProxyHandler(BaseHTTPRequestHandler):
    def get_identity_token(self):
        target_url = os.environ["TARGET_URL"]
        r = requests.get(
            f"http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience={target_url}",
            headers={"Metadata-Flavor": "Google"},
            timeout=5,
        )
        r.raise_for_status()
        return r.text

    def proxy_request(self, method):
        target_url = os.environ.get("TARGET_URL")
        if not target_url:
            self.send_error(500, "TARGET_URL not configured")
            return
        try:
            token = self.get_identity_token()
            full_url = target_url + self.path
            hop_by_hop = {
                "host", "connection", "keep-alive", "proxy-authenticate",
                "proxy-authorization", "te", "trailers", "transfer-encoding", "upgrade",
            }
            headers = {h: v for h, v in self.headers.items() if h.lower() not in hop_by_hop}
            headers["Authorization"] = f"Bearer {token}"
            headers["Host"] = urlparse(target_url).netloc

            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length) if content_length > 0 else None

            logging.info("%s %s -> %s", method, self.path, full_url)
            r = requests.request(
                method=method, url=full_url, headers=headers, data=body,
                timeout=30, allow_redirects=False,
            )

            self.send_response(r.status_code)
            for h, v in r.headers.items():
                if h.lower() not in hop_by_hop:
                    self.send_header(h, v)
            self.end_headers()
            self.wfile.write(r.content)
        except Exception as e:
            logging.error("proxy error: %s", e)
            self.send_error(502, f"Proxy error: {e}")

    def do_GET(self):     self.proxy_request("GET")
    def do_POST(self):    self.proxy_request("POST")
    def do_PUT(self):     self.proxy_request("PUT")
    def do_DELETE(self):  self.proxy_request("DELETE")
    def do_PATCH(self):   self.proxy_request("PATCH")
    def do_HEAD(self):    self.proxy_request("HEAD")
    def do_OPTIONS(self): self.proxy_request("OPTIONS")

    def log_message(self, fmt, *args):
        logging.info(fmt % args)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    if not os.environ.get("TARGET_URL"):
        logging.error("TARGET_URL environment variable must be set")
        sys.exit(1)
    logging.info("starting proxy on :%d -> %s", port, os.environ["TARGET_URL"])
    HTTPServer(("0.0.0.0", port), CloudRunProxyHandler).serve_forever()
