#!/usr/bin/env python3
"""Serve the mirror locally with 1999-correct content types."""
import http.server, socketserver, sys, os

os.chdir(sys.argv[1])
PORT = int(sys.argv[2])

class H(http.server.SimpleHTTPRequestHandler):
    def guess_type(self, path):
        for ext in (".shtml", ".cgi", ".php", ".html"):
            if path.endswith(ext):
                return "text/html; charset=windows-1252"
        return super().guess_type(path)
    def log_message(self, *a):
        pass

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT), H) as httpd:
    httpd.serve_forever()
