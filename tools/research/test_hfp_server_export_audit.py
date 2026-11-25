"""Regression tests for HFP/Server export metadata-only gate."""
import copy
import unittest

from hfp_server_export_audit import parse_dumpbin_exports, analyze_imports, meta_exports


def dumpbin(rows, count):
    return ("File Type: DLL\n\n    1 ordinal base\n"
            f"    {count} number of names\n\n"
            "    ordinal hint RVA      name\n\n" + "\n".join(rows) +
            "\n\n  Summary\n        1000 .text\n")


class ExportClosureTests(unittest.TestCase):
    def setUp(self):
        self.export = {
            'hal.dll': {'KeQueryPerformanceCounter': {'ordinal': 1, 'forwarder': ['ntoskrnl', 'KeQueryPerformanceCounter']}},
            'ntoskrnl.exe': {'KeQueryPerformanceCounter': {'ordinal': 2, 'forwarder': None},
                             'KeSetEvent': {'ordinal': 3, 'forwarder': None}},
            'btampm.sys': {'BtaMpmRegister': {'ordinal': 1, 'forwarder': None}},
        }
        self.hfp = {
            'hfp-pe/BthHfEnum.sys-test.json': {
                'hashes': {'sha256': 'fixture'},
                'imports': [
                    {'dll': 'HAL.dll', 'symbols': [{'name': 'KeQueryPerformanceCounter', 'ordinal': None}]},
                    {'dll': 'ntoskrnl.exe', 'symbols': [{'name': 'KeSetEvent', 'ordinal': None}]},
                    {'dll': 'btampm.sys', 'symbols': [{'name': 'BtaMpmRegister', 'ordinal': None}]}
                ]
            }
        }

    def test_parse_complete_with_hex_hint_and_forwarder(self):
        raw=dumpbin([
            '          1    A 1234ABCD KeSetEvent',
            '          2    B          KeQueryPerformanceCounter (forwarded to ntoskrnl.KeQueryPerformanceCounter)'
        ],2)
        e=parse_dumpbin_exports(raw)
        self.assertEqual(len(e),2)
        self.assertEqual(e['KeQueryPerformanceCounter']['forwarder'],['ntoskrnl','KeQueryPerformanceCounter'])

    def test_skip_unnamed_ordinal_export(self):
        raw=dumpbin(['          1      0011ABCD [NONAME]', '          2   1F 00001234 KeSetEvent'],1)
        self.assertEqual(list(parse_dumpbin_exports(raw)),['KeSetEvent'])

    def test_incomplete_inventory_fails_closed(self):
        with self.assertRaises(ValueError):
            parse_dumpbin_exports(dumpbin(['          1   0 00000010 Test'], 2))

    def test_full_positive_import_and_transitive_forwarder(self):
        report=analyze_imports(self.hfp, self.export)
        self.assertTrue(report[0]['passed'])
        self.assertEqual(report[0]['imports_total'],3)
        self.assertEqual(len(report[0]['modules'][0]['forwarded']),1)

    def test_missing_name_rejected(self):
        exports=copy.deepcopy(self.export)
        del exports['btampm.sys']['BtaMpmRegister']
        self.assertFalse(analyze_imports(self.hfp,exports)[0]['passed'])

    def test_missing_forwarder_destination_rejected(self):
        exports=copy.deepcopy(self.export)
        del exports['ntoskrnl.exe']['KeQueryPerformanceCounter']
        p=analyze_imports(self.hfp,exports)[0]
        self.assertFalse(p['passed'])
        self.assertEqual(len(p['modules'][0]['forwarder_missing']),1)

    def test_missing_dll_rejected(self):
        exports=copy.deepcopy(self.export)
        del exports['btampm.sys']
        self.assertFalse(analyze_imports(self.hfp,exports)[0]['passed'])

    def test_ordinal_import_rejected(self):
        hfp=copy.deepcopy(self.hfp)
        hfp['hfp-pe/BthHfEnum.sys-test.json']['imports'][1]['symbols'][0]={'name':None,'ordinal':3}
        self.assertFalse(analyze_imports(hfp,self.export)[0]['passed'])

    def test_truncated_pe_table_fails_closed(self):
        hfp=copy.deepcopy(self.hfp)
        hfp['hfp-pe/BthHfEnum.sys-test.json']['imports'][0]['count']=2
        with self.assertRaises(ValueError):
            analyze_imports(hfp,self.export)

    def test_export_list_support_and_no_named_substitution(self):
        self.assertEqual(len(meta_exports([{'name':'BtaMpmRegister','ordinal':1}, {'name':None, 'ordinal':2}])),1)

    def test_duplicate_exports_rejected(self):
        with self.assertRaises(ValueError):
            parse_dumpbin_exports(dumpbin(['          1   0 00001234 Dup', '          2   1 00005678 Dup'],2))


if __name__ == '__main__':
    unittest.main()