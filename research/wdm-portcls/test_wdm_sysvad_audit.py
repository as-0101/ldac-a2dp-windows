import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from wdm_sysvad_audit import scan, PATHS

DATA = {
'inf': '''[Version]\nCatalogFile=sysvad.cat\n[SYSVAD.Install]\nInclude=ks.inf,wdmaudio.inf\nNeeds=KS.Registration, WDMAUDIO.Registration\nAddInterface=%KSCATEGORY_RENDER%,%KSNAME_WaveBthHfpSpeaker%,SYSVAD.I.WaveBthHfpSpeaker\nAddInterface=%KSCATEGORY_CAPTURE%,%KSNAME_WaveBthHfpMic%,SYSVAD.I.WaveBthHfpMic\n''',
'project': '<PlatformToolset>WindowsKernelModeDriver10.0</PlatformToolset><TargetVersion>Windows10</TargetVersion><PreprocessorDefinitions>SYSVAD_BTH_BYPASS</PreprocessorDefinitions>',
'hfp': '#include <bthhfpddi.h>\nIOCTL_BTHHFP_DEVICE_GET_DESCRIPTOR2',
'a2dp':'#ifdef SYSVAD_A2DP_SIDEBAND\n#endif',
'pairs': 'BthHfpSpeakerMiniports BthHfpMicMiniports'
}

class AuditTests(unittest.TestCase):
    def fixture(self, overwrite=None):
        td=TemporaryDirectory()
        d=Path(td.name)
        for k, f in PATHS.items():
            p=d/f; p.parent.mkdir(parents=True,exist_ok=True); p.write_text((overwrite or {}).get(k,DATA[k]),encoding='utf-8')
        return td,d
    def test_positive(self):
        td,d=self.fixture()
        with td:
            r=scan(d); self.assertTrue(r['passed'],r['checks']); self.assertEqual(len(r['source_file_sha256']),5)
    def test_render_only_rejected(self):
        td,d=self.fixture({'inf':DATA['inf'].replace('KSCATEGORY_CAPTURE','KSCATEGORY_RENDER')})
        with td:
            r=scan(d); self.assertFalse(r['passed']); self.assertFalse(r['checks']['inf_hfp_capture'])
    def test_no_hfp_provider_rejected(self):
        td,d=self.fixture({'hfp':'// no bthhfpddi.h and no ioctl'})
        with td:
            r=scan(d); self.assertFalse(r['passed']); self.assertFalse(r['checks']['hfp_sideband_ioctl_dependency'])
    def test_comment_not_sufficient(self):
        td,d=self.fixture({'inf':'[Version]\n; AddInterface=%KSCATEGORY_CAPTURE%,%KSNAME_WaveBthHfpMic%\n'+DATA['inf'].replace('KSCATEGORY_CAPTURE','NONE')})
        with td:
            self.assertFalse(scan(d)['checks']['inf_hfp_capture'])

if __name__=='__main__': unittest.main()
