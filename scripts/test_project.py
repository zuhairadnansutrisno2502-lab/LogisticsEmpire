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
if __name__ == '__main__':
    unittest.main()
