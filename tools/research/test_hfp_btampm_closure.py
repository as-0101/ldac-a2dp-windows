import os
import unittest
from pathlib import Path
from hfp_btampm_closure import names_for_closure, build_report

class ClosureTests(unittest.TestCase):
    def test_all_names(self):
        self.assertEqual(names_for_closure(['X','Y'], [{'name':'Y','forwarder':None},{'name':'X','forwarder':None}]), [])
    def test_missing_name(self):
        self.assertEqual(names_for_closure(['X','Y'], [{'name':'X','forwarder':None}]), ['Y'])
    def test_forwarder_not_a_direct_match(self):
        self.assertEqual(names_for_closure(['X'], [{'name':'X','forwarder':'elsewhere.X'}]), ['X'])
    def test_real_archives(self):
        hp = Path(os.environ.get('HFP_METADATA_ZIP', 'hfp-ci-metadata.zip'))
        ap = Path(os.environ.get('A2DP_METADATA_ZIP', 'a2dp-donor-results.zip'))
        if not hp.is_file() or not ap.is_file():
            self.skipTest('Set HFP_METADATA_ZIP and A2DP_METADATA_ZIP to enable archive test')
        with hp.open('rb') as f:
            hf = f.read()
        with ap.open('rb') as f:
            ad = f.read()
        j=build_report(hf,ad)
        self.assertEqual(len(j['enum_versions']),2)
        self.assertEqual(j['bta_export_count'],14)
        self.assertTrue(j['all_7_imports_resolve'])
        self.assertNotEqual(j['enum_versions'][0]['driver_sha256'],j['enum_versions'][1]['driver_sha256'])

if __name__ == '__main__': unittest.main()