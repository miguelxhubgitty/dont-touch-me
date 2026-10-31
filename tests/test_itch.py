import importlib.util, pathlib, unittest
from unittest.mock import patch

ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('itch',ROOT/'release/tools/itch.py')
itch=importlib.util.module_from_spec(spec); spec.loader.exec_module(itch)

class ItchTests(unittest.TestCase):
    def test_path_escape(self):
        with self.assertRaises(ValueError): itch.inside(ROOT,'../escape')
    def test_free_policy(self):
        with self.assertRaises(ValueError): itch.validate(ROOT,{'pricing':{}},'windows')
    def test_unvalidated_native_runtime(self):
        catalog=itch.read(ROOT/'release/catalog/game.json')
        manifest={'version':catalog['version'],'artifacts':{'linux':{'status':'built','validation':{'structure':'passed','runtime':'not run'}}}}
        with patch.object(itch,'read',return_value=manifest):
            with self.assertRaisesRegex(ValueError,'runtime'): itch.validate(ROOT,catalog,'linux')
    def test_wrong_version(self):
        catalog=itch.read(ROOT/'release/catalog/game.json')
        with patch.object(itch,'read',return_value={'version':'9.9.9'}):
            with self.assertRaisesRegex(ValueError,'version'): itch.validate(ROOT,catalog,'windows')
    def test_bad_structure(self):
        catalog=itch.read(ROOT/'release/catalog/game.json')
        manifest={'version':catalog['version'],'artifacts':{'windows':{'status':'failed'}}}
        with patch.object(itch,'read',return_value=manifest):
            with self.assertRaisesRegex(ValueError,'structurally'): itch.validate(ROOT,catalog,'windows')

if __name__=='__main__': unittest.main()
