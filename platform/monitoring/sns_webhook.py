#!/usr/bin/env python3
import hmac
import json
import logging
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_REQUEST_BYTES = 64 * 1024
MAX_SNS_MESSAGE_BYTES = 200_000
MAX_ALERTS = 50


class PublishError(Exception):
    pass


def build_notification(payload):
    if not isinstance(payload, dict) or payload.get("status") not in {"firing", "resolved"}:
        raise ValueError("An Alertmanager firing or resolved payload is required.")

    alerts = payload.get("alerts")
    if not isinstance(alerts, list) or not alerts or len(alerts) > MAX_ALERTS:
        raise ValueError(f"Payload must contain 1-{MAX_ALERTS} alerts.")

    lines = []
    names = []
    for alert in alerts:
        if not isinstance(alert, dict):
            raise ValueError("Every alert must be an object.")
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})
        if not isinstance(labels, dict) or not isinstance(annotations, dict):
            raise ValueError("Alert labels and annotations must be objects.")

        name = labels.get("alertname", "Alert")
        severity = labels.get("severity", "unknown")
        summary = annotations.get("summary", name)
        description = annotations.get("description", "No description provided.")
        alert_status = alert.get("status", payload["status"])
        if not all(
            isinstance(value, str)
            for value in (name, severity, summary, description, alert_status)
        ):
            raise ValueError("Alert names, status, severity, and annotations must be strings.")

        names.append(name)
        lines.extend(
            [
                f"[{alert_status}] {name} ({severity})",
                f"Summary: {summary}",
                f"Description: {description}",
            ]
        )

    subject = f"[{payload['status'].upper()}] {', '.join(names)}"
    subject = subject.encode("utf-8")[:100].decode("utf-8", errors="ignore")
    message = "\n".join(lines)
    if len(message.encode("utf-8")) > MAX_SNS_MESSAGE_BYTES:
        raise ValueError("Formatted notification exceeds the SNS message size limit.")
    return subject, message


def publish_notification(topic_arn, region, subject, message):
    try:
        result = subprocess.run(
            [
                "aws",
                "sns",
                "publish",
                "--region",
                region,
                "--topic-arn",
                topic_arn,
                "--subject",
                subject,
                "--message",
                message,
                "--output",
                "json",
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PublishError("Unable to execute AWS SNS publish.") from error
    if result.returncode != 0:
        raise PublishError(f"AWS SNS publish exited with status {result.returncode}.")


def process_notification(authorization, body, token, topic_arn, region):
    if not isinstance(authorization, str) or not hmac.compare_digest(
        authorization, f"Bearer {token}"
    ):
        return 401, b"Unauthorized\n"
    try:
        payload = json.loads(body)
        subject, message = build_notification(payload)
    except (json.JSONDecodeError, UnicodeDecodeError, ValueError):
        return 400, b"Invalid alert payload\n"

    try:
        publish_notification(topic_arn, region, subject, message)
    except PublishError:
        logging.exception("AWS SNS notification delivery failed.")
        return 502, b"Notification delivery failed\n"
    return 202, b"Accepted\n"


def make_handler(token, topic_arn, region):
    class SNSWebhookHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/healthz":
                self.respond(200, b"ok\n")
            else:
                self.respond(404, b"Not found\n")

        def do_POST(self):
            if self.path != "/alerts":
                self.respond(404, b"Not found\n")
                return
            try:
                content_length = int(self.headers.get("Content-Length", ""))
            except ValueError:
                self.respond(411, b"Content-Length required\n")
                return
            if content_length < 0 or content_length > MAX_REQUEST_BYTES:
                self.respond(413, b"Payload too large\n")
                return

            body = self.rfile.read(content_length)
            if len(body) != content_length:
                self.respond(400, b"Incomplete payload\n")
                return
            status, response = process_notification(
                self.headers.get("Authorization"),
                body,
                token,
                topic_arn,
                region,
            )
            self.respond(status, response)

        def respond(self, status, body):
            self.send_response(status)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, format_string, *args):
            return

    return SNSWebhookHandler


def main():
    token_file = Path(os.environ["SNS_WEBHOOK_TOKEN_FILE"])
    token = token_file.read_text(encoding="utf-8").strip()
    topic_arn = os.environ["SNS_TOPIC_ARN"]
    region = os.environ["AWS_DEFAULT_REGION"]
    if not token or not topic_arn or not region:
        raise ValueError("Webhook token, SNS topic, and AWS region must be configured.")

    address = os.environ.get("SNS_WEBHOOK_BIND_ADDRESS", "10.42.0.1")
    port = int(os.environ.get("SNS_WEBHOOK_PORT", "9811"))
    server = ThreadingHTTPServer((address, port), make_handler(token, topic_arn, region))
    server.daemon_threads = True
    logging.info("SNS webhook listener is ready on %s:%s.", address, port)
    server.serve_forever()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    main()
