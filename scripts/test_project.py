#!/usr/bin/env python3
"""Starter validation: structural contract, not gameplay test coverage."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent.parent
class StarterTests(unittest.TestCase):
    def test_rojo_project(self):
        data = json.loads((ROOT / 'default.project.json').read_text())
        self.assertEqual(data['name'], 'LogisticsEmpire')
        self.assertIn('ReplicatedStorage', data['tree'])
        self.assertIn('ServerScriptService', data['tree'])
    def test_prompts(self):
        for name in ('CODEX_MASTER_PROMPT.md', 'CLAUDE_MASTER_PROMPT.md', 'BRIDGE_RUNBOOK.md', 'API_CONTRACT.md'):
            self.assertTrue((ROOT / 'docs' / name).is_file(), name)
    def test_agent_sync(self):
        self.assertTrue((ROOT / 'scripts' / 'agent_sync.py').exists())
    def test_ownership_rules(self):
        import sys
        sys.path.insert(0, str(ROOT / 'scripts'))
        from check_ownership import violations
        self.assertEqual(violations('visual/codex', ['src/client/UI/App.luau', 'assets/x.rbxm']), [])
        self.assertEqual(violations('visual/codex-fleet', ['src/server/init.server.luau']), ['src/server/init.server.luau'])
        self.assertEqual(violations('systems/claude', ['src/server/Services/Rules.luau', 'tests/a.spec.luau']), [])
        self.assertEqual(violations('systems/claude', ['src/client/Controllers/Store.luau', 'src/client/init.client.luau']), [])
        self.assertEqual(violations('systems/claude', ['src/client/UI/App.luau']), ['src/client/UI/App.luau'])
        self.assertEqual(violations('visual/codex', ['src/client/Controllers/Store.luau']), ['src/client/Controllers/Store.luau'])
        self.assertEqual(violations('integration/x', ['.github/workflows/validate.yml', 'docs/SETUP_STATUS.md']), [])
        self.assertEqual(violations('integration/x', ['docs/API_CONTRACT.md', 'src/client/UI/a.luau']), ['docs/API_CONTRACT.md', 'src/client/UI/a.luau'])
        self.assertIsNone(violations('feature/x', ['README.md']))
if __name__ == '__main__':
    unittest.main()
