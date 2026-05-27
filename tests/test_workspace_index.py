#!/usr/bin/env python3
"""Unit tests for ARIA-EX1 workspace index (run: python tests/test_workspace_index.py)."""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PLUGIN = REPO / "plugin"
sys.path.insert(0, str(PLUGIN))

from workspace_knowledge import db, execution, parsers  # noqa: E402
from workspace_knowledge.bootstrap import init_workspace  # noqa: E402
from workspace_knowledge.indexer import index_file  # noqa: E402
from workspace_knowledge.search import knowledge_search  # noqa: E402


class WorkspaceIndexTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ.pop("ARIA_EX1_DB_PATH", None)
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / ".md" / "handoff" / "demo").mkdir(parents=True)
        handoff = self.root / ".md" / "handoff" / "demo" / "2026-05-26T12-00-00Z.md"
        handoff.write_text(
            "# Demo handoff\n\nFiles changed: demo.py\n\n```bash\necho hi\n```\n",
            encoding="utf-8",
        )
        self.db_path = self.root / ".aria-ex1" / "workspace_index.sqlite"

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_bootstrap_and_index(self) -> None:
        result = init_workspace(self.root, full_index=True)
        self.assertTrue(self.db_path.is_file())
        self.assertIn("workspace_id", result)
        stats = result.get("index_stats") or {}
        self.assertGreaterEqual(stats.get("indexed", 0), 1)

    def test_fts_search(self) -> None:
        init_workspace(self.root, full_index=True)
        with db.connect(self.db_path) as conn:
            db.init_db(conn)
            wid = db.ensure_workspace(conn, self.root)
            hits = knowledge_search(conn, query="demo.py", workspace_id=wid)
            self.assertTrue(any("handoff" in h["kind"] for h in hits))

    def test_bloat_score(self) -> None:
        heavy = "option A and alternatively option B " * 5
        score = execution.bloat_score(heavy, tier="full")
        self.assertGreaterEqual(score, 4)

    def test_section_split(self) -> None:
        body = "## Follow-up — 2026-05-26T12-00-00Z\n\nMore text.\n"
        sections = parsers.split_handoff_sections("doc1", body)
        self.assertGreaterEqual(len(sections), 1)


if __name__ == "__main__":
    unittest.main()
