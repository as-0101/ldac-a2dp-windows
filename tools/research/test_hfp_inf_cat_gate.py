import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from hfp_inf_cat_gate import audit, sections_of, inf_summary, strip_comment, read_text

GOOD = r'''[Version]
Signature="$Windows NT$"
CatalogFile=microsoft_bluetooth_hfp.cat
[Manufacturer]
%Microsoft%=Microsoft, NTamd64
[Microsoft.NTamd64]
%Audio%=Common_BthHfAud_Install,BTHHFENUM\BthHFPAudio
[Common_BthHfAud_Install.NT]
CopyFiles=Hfp.CopyFiles
[Common_BthHfAud_Install.NT.Services]
AddService=BthHfAud,0x00000002,Service
[Service]
ServiceBinary=%12%\BthHfAud.sys
'''
class HfpInfCatGateTests(unittest.TestCase):
    def create(self,text=GOOD,cat=True):
        td=TemporaryDirectory(); d=Path(td.name)
        (d/'microsoft_bluetooth_hfp.inf').write_text(text,encoding='utf8')
        if cat:(d/'microsoft_bluetooth_hfp.cat').write_bytes(b'not signed test control')
        (d/'BthHfAud.sys').write_bytes(b'not an authentic driver; never load')
        return td,d
    def test_missing_root_blocks(self):
        with TemporaryDirectory() as d:
            self.assertEqual(audit(Path(d)/'nonexistent')['reason'],'donor_root_missing')
    def test_empty_root_blocks(self):
        with TemporaryDirectory() as d:
            self.assertEqual(audit(Path(d))['reason'],'original_hfp_inf_unavailable')
    def test_synthetic_complete_not_signature_proof(self):
        td,d=self.create()
        with td:
            a=audit(d); p=a['packages'][0]
            self.assertEqual(a['status'],'STATIC_INSPECTED')
            self.assertTrue(p['candidate_complete'])
            self.assertEqual(p['signature_gate'],'UNTESTED')
            self.assertEqual(p['catalogs'][0]['member_verification'],'UNTESTED')
            self.assertFalse(a['runtime_gate'] == 'CONFIRMED')
    def test_missing_cat_rejected(self):
        td,d=self.create(cat=False)
        with td:
            p=audit(d)['packages'][0]
            self.assertFalse(p['candidate_complete'])
    def test_missing_service_rejected(self):
        td,d=self.create(text=GOOD.replace('AddService=BthHfAud','AddNothing=BthHfAud'))
        with td:self.assertFalse(audit(d)['packages'][0]['candidate_complete'])
    def test_missing_hardware_id_rejected(self):
        td,d=self.create(text=GOOD.replace('BTHHFENUM\\BthHFPAudio','EXAMPLE\\device'))
        with td:self.assertFalse(audit(d)['packages'][0]['candidate_complete'])
    def test_cant_infer_catalog_from_name(self):
        td,d=self.create(text=GOOD.replace('CatalogFile=microsoft_bluetooth_hfp.cat','CatalogFile=missing.cat'))
        with td:self.assertFalse(audit(d)['packages'][0]['candidate_complete'])
    def test_missing_sys_rejected(self):
        td,d=self.create()
        with td:
            (d/'BthHfAud.sys').unlink()
            self.assertFalse(audit(d)['packages'][0]['candidate_complete'])
    def test_string_comment_preserved(self):
        self.assertEqual(strip_comment('X="A;B" ; trail'),'X="A;B" ')
    def test_section_continuation(self):
        x=sections_of('[A]\nNeeds=One, \\\n Two\n')
        self.assertEqual(x['a'],['Needs=One, Two'])
    def test_duplicate_section_fails(self):
        with self.assertRaises(ValueError):sections_of('[A]\n[A]\n')
    def test_utf16_inf_supported(self):
        td,d=self.create()
        with td:
            f=d/'microsoft_bluetooth_hfp.inf';f.write_text(GOOD,encoding='utf-16')
            self.assertTrue(audit(d)['packages'][0]['candidate_complete'])
    def test_comment_faked_service_not_enough(self):
        td,d=self.create(text=GOOD.replace('AddService=BthHfAud','; AddService=BthHfAud'))
        with td:self.assertFalse(audit(d)['packages'][0]['candidate_complete'])
if __name__=='__main__':unittest.main()