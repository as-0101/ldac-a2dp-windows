import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch as mock
import prepare_btampm as m

# Partial structural fixture from actual CI inf-summary; not full original INF.
FIXTURE = '[Version]\nClass=SYSTEM\n[BtaMPM.CopyFilesOnly]\nCopyFiles=BtaMPM.CopyFiles\n[BtaMPM.CopyFiles]\nBtaMPM.sys,,,0x0100\n'

class Tests(unittest.TestCase):
    def test_lossless_encodings(self):
        for bom, enc in ((b'', 'ascii'), (b'\xff\xfe', 'utf-16-le'), (b'\xef\xbb\xbf', 'utf-8')):
            for nl in ('\n', '\r\n'):
                with self.subTest(enc=enc,nl=nl):
                    src = bom + FIXTURE.replace('\n', nl).encode(enc)
                    out = m.patch(src)
                    self.assertEqual(out.replace((m.CAT_LINE + nl).encode(enc), b'', 1), src)
                    self.assertEqual(out.count(m.CAT_LINE.encode(enc)), 1)
    def test_existing_catalog(self):
        with self.assertRaises(ValueError): m.patch(FIXTURE.replace('Class=SYSTEM', 'CatalogFile=x.cat').encode())
    def test_missing_version(self):
        with self.assertRaises(ValueError): m.patch(FIXTURE.replace('[Version]', '[Other]').encode())
    def test_duplicate_version(self):
        with self.assertRaises(ValueError): m.patch(('[Version]\n'+FIXTURE).encode())
    def test_missing_copy_section(self):
        with self.assertRaises(ValueError): m.patch(FIXTURE.replace('[BtaMPM.CopyFiles]', '[Other]').encode())
    def test_hash_gate_and_preserve_sys(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d); inf = p/'source.inf'; sys = p/'source.sys'; out = p/'out'
            inf.write_bytes(FIXTURE.encode()); sys.write_bytes(b'fixture, not a driver')
            with self.assertRaises(ValueError): m.prepare(inf, sys, out)
            self.assertFalse(out.exists())
            with mock.object(m, 'INF_SHA', m.sha(inf.read_bytes())), mock.object(m, 'SYS_SHA', m.sha(sys.read_bytes())):
                m.prepare(inf, sys, out)
                self.assertEqual((out/'BtaMPM.sys').read_bytes(), sys.read_bytes())
                self.assertEqual(inf.read_bytes(), FIXTURE.encode())
                with self.assertRaises(FileExistsError): m.prepare(inf, sys, out)

if __name__ == '__main__': unittest.main(verbosity=2)
