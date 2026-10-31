import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("update-image-digest.py")
SPEC = importlib.util.spec_from_file_location("update_image_digest", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load {MODULE_PATH}")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class UpdateImageDigestTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.path = Path(self.directory.name) / "values.yaml"
        self.path.write_text(
            "image:\n"
            "  repository: example/app\n"
            f"  digest: sha256:{'a' * 64}\n"
            f"  sourceCommit: {'b' * 40}\n"
            "  pullPolicy: IfNotPresent\n"
            "database:\n"
            "  image: postgres:17-alpine\n"
            f"  digest: sha256:{'c' * 64}\n",
            encoding="utf-8",
        )

    def tearDown(self):
        self.directory.cleanup()

    def test_updates_app_digest_without_touching_database_digest(self):
        new_digest = f"sha256:{'d' * 64}"
        new_commit = "e" * 40

        MODULE.update_image_values(self.path, new_digest, new_commit)
        values = self.path.read_text(encoding="utf-8")

        self.assertIn(f"  digest: {new_digest}\n", values)
        self.assertIn(f"  sourceCommit: {new_commit}\n", values)
        self.assertIn(f"  digest: sha256:{'c' * 64}\n", values)

    def test_rejects_invalid_image_digest(self):
        with self.assertRaisesRegex(ValueError, "sha256 digest"):
            MODULE.update_image_values(self.path, "latest", "e" * 40)

    def test_rejects_missing_or_ambiguous_app_digest(self):
        text = self.path.read_text(encoding="utf-8")
        self.path.write_text(text.replace(f"  digest: sha256:{'a' * 64}\n", ""), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "image.digest"):
            MODULE.update_image_values(self.path, f"sha256:{'d' * 64}", "e" * 40)


if __name__ == "__main__":
    unittest.main()
