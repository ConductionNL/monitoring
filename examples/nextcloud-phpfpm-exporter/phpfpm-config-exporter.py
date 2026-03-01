#!/usr/bin/env python3
"""
Minimale "exporter" die pm.max_children, pm.start_servers, pm.min_spare_servers, pm.max_spare_servers
uit een PHP-FPM pool-config leest en als Prometheus-metrics op :9254/metrics serveert.
Draai als sidecar in de Nextcloud-pod (waar de pool-config staat); mount het config-pad.
Gebruik: CONFIG_PATH=/path/to/pool.conf python3 phpfpm-config-exporter.py
"""
import os
import re
import http.server

CONFIG_PATH = os.environ.get("CONFIG_PATH", "/usr/local/etc/php-fpm.d/www.conf")
PORT = int(os.environ.get("PORT", "9254"))
METRICS = {}

def parse_config():
    global METRICS
    METRICS = {}
    try:
        with open(CONFIG_PATH) as f:
            for line in f:
                line = line.strip().split(";")[0].strip()
                for key, name in [
                    ("pm.max_children", "php_fpm_config_max_children"),
                    ("pm.start_servers", "php_fpm_config_start_servers"),
                    ("pm.min_spare_servers", "php_fpm_config_min_spare_servers"),
                    ("pm.max_spare_servers", "php_fpm_config_max_spare_servers"),
                ]:
                    if line.startswith(key + " "):
                        m = re.match(r"%s\s*=\s*(\d+)" % re.escape(key), line)
                        if m:
                            METRICS[name] = int(m.group(1))
                        break
    except Exception:
        pass

def metrics_handler():
    parse_config()
    lines = [
        "# HELP php_fpm_config_max_children Configured pm.max_children",
        "# TYPE php_fpm_config_max_children gauge",
        "php_fpm_config_max_children %s" % METRICS.get("php_fpm_config_max_children", 0),
        "# HELP php_fpm_config_start_servers Configured pm.start_servers",
        "# TYPE php_fpm_config_start_servers gauge",
        "php_fpm_config_start_servers %s" % METRICS.get("php_fpm_config_start_servers", 0),
        "# HELP php_fpm_config_min_spare_servers Configured pm.min_spare_servers",
        "# TYPE php_fpm_config_min_spare_servers gauge",
        "php_fpm_config_min_spare_servers %s" % METRICS.get("php_fpm_config_min_spare_servers", 0),
        "# HELP php_fpm_config_max_spare_servers Configured pm.max_spare_servers",
        "# TYPE php_fpm_config_max_spare_servers gauge",
        "php_fpm_config_max_spare_servers %s" % METRICS.get("php_fpm_config_max_spare_servers", 0),
    ]
    return "\n".join(lines) + "\n"

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics" or self.path == "/metrics/":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(metrics_handler().encode())
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, *args): pass

def main():
    server = http.server.HTTPServer(("", PORT), Handler)
    server.serve_forever()

if __name__ == "__main__":
    main()
