import importlib.util
import pathlib
import sys
import types
import unittest
from types import SimpleNamespace

ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools" / "research" / "audit_pe_binary.py"

# The tested helper only needs the pefile module name for annotations.
# Stub it so this regression test can run without parsing any binary fixture.
pefile_stub = types.ModuleType("pefile")
pefile_stub.PE = type("PE", (), {})
pefile_stub.DIRECTORY_ENTRY = {}
sys.modules.setdefault("pefile", pefile_stub)

spec = importlib.util.spec_from_file_location("audit_pe_binary", MODULE_PATH)
audit = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(audit)


class ImportHintRegressionTests(unittest.TestCase):
    def test_named_delay_import_with_missing_hint_is_preserved(self):
        descriptor = SimpleNamespace(
            dll=b"AudioEndpointBuilder.dll",
            imports=[SimpleNamespace(name=b"ExampleImport", ordinal=None, hint=None)],
        )
        result = audit.collect_import_table(
            SimpleNamespace(DIRECTORY_ENTRY_DELAY_IMPORT=[descriptor]),
            "DIRECTORY_ENTRY_DELAY_IMPORT",
        )
        self.assertEqual(result[0]["dll"], "AudioEndpointBuilder.dll")
        self.assertEqual(result[0]["symbols"][0]["name"], "ExampleImport")
        self.assertIsNone(result[0]["symbols"][0]["hint"])

    def test_ordinal_import_with_missing_hint_is_preserved(self):
        descriptor = SimpleNamespace(
            dll=b"example.dll",
            imports=[SimpleNamespace(name=None, ordinal=17, hint=None)],
        )
        result = audit.collect_import_table(
            SimpleNamespace(DIRECTORY_ENTRY_IMPORT=[descriptor]),
            "DIRECTORY_ENTRY_IMPORT",
        )
        self.assertEqual(result[0]["symbols"][0]["ordinal"], 17)
        self.assertIsNone(result[0]["symbols"][0]["hint"])

    def test_named_import_retains_numeric_hint(self):
        descriptor = SimpleNamespace(
            dll=b"example.dll",
            imports=[SimpleNamespace(name=b"NamedImport", ordinal=None, hint=9)],
        )
        result = audit.collect_import_table(
            SimpleNamespace(DIRECTORY_ENTRY_IMPORT=[descriptor]),
            "DIRECTORY_ENTRY_IMPORT",
        )
        self.assertEqual(result[0]["symbols"][0]["hint"], 9)


if __name__ == "__main__":
    unittest.main()
