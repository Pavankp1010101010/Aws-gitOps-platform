import json
import unittest
from unittest.mock import patch

from sns_webhook import PublishError, build_notification, process_notification


class SNSWebhookTests(unittest.TestCase):
    def setUp(self):
        self.payload = {
            "status": "firing",
            "alerts": [
                {
                    "status": "firing",
                    "labels": {"alertname": "Synthetic", "severity": "warning"},
                    "annotations": {
                        "summary": "Synthetic alert fired",
                        "description": "Safe notification test.",
                    },
                }
            ],
        }

    def test_builds_firing_and_resolved_messages(self):
        subject, message = build_notification(self.payload)
        self.assertEqual(subject, "[FIRING] Synthetic")
        self.assertIn("Safe notification test.", message)

        self.payload["status"] = "resolved"
        subject, _ = build_notification(self.payload)
        self.assertEqual(subject, "[RESOLVED] Synthetic")

    def test_rejects_malformed_or_oversized_alert_groups(self):
        with self.assertRaises(ValueError):
            build_notification({"status": "pending", "alerts": []})
        with self.assertRaises(ValueError):
            build_notification({"status": "firing", "alerts": [{}] * 51})

    @patch("sns_webhook.publish_notification")
    def test_requires_bearer_token_before_publishing(self, publish):
        status, _ = process_notification(
            "Bearer wrong", json.dumps(self.payload), "expected", "topic", "region"
        )
        self.assertEqual(status, 401)
        publish.assert_not_called()

    @patch("sns_webhook.publish_notification")
    def test_publishes_only_valid_authenticated_alerts(self, publish):
        status, _ = process_notification(
            "Bearer expected", json.dumps(self.payload), "expected", "topic", "region"
        )
        self.assertEqual(status, 202)
        publish.assert_called_once()
        self.assertEqual(publish.call_args.args[:2], ("topic", "region"))

    @patch("sns_webhook.publish_notification", side_effect=PublishError("failed"))
    def test_surfaces_notification_delivery_failure(self, publish):
        status, _ = process_notification(
            "Bearer expected", json.dumps(self.payload), "expected", "topic", "region"
        )
        self.assertEqual(status, 502)
        publish.assert_called_once()


if __name__ == "__main__":
    unittest.main()
