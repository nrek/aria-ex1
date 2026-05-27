-- ARIA-EX1 workspace_index.sqlite schema (v1)
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS schema_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS workspaces (
  id TEXT PRIMARY KEY,
  root_path TEXT NOT NULL UNIQUE,
  name TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS repo_groups (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  name TEXT NOT NULL,
  backend_path TEXT,
  stitch_path TEXT,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
);

CREATE TABLE IF NOT EXISTS repositories (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  repo_group_id TEXT,
  name TEXT NOT NULL,
  path TEXT NOT NULL,
  stack TEXT,
  role TEXT CHECK(role IN ('backend','frontend','mobile','docs','infra','unknown')) DEFAULT 'unknown',
  codemap_path TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (repo_group_id) REFERENCES repo_groups(id)
);

CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  repo_id TEXT,
  kind TEXT NOT NULL CHECK(kind IN (
    'codemap','stitch','task','plan','handoff','decision','rule','blueprint','note','unknown'
  )),
  status TEXT,
  project TEXT,
  path TEXT NOT NULL,
  title TEXT,
  summary TEXT,
  body TEXT NOT NULL,
  body_hash TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  indexed_at TEXT NOT NULL DEFAULT (datetime('now')),
  plan_status TEXT,
  linear_task_id TEXT,
  files_changed TEXT,
  deploy_commands TEXT,
  tags_json TEXT,
  folder_status TEXT,
  status_mismatch INTEGER NOT NULL DEFAULT 0,
  metadata_json TEXT,
  UNIQUE(workspace_id, path),
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (repo_id) REFERENCES repositories(id)
);

CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
  document_id UNINDEXED,
  title,
  summary,
  body,
  project,
  kind UNINDEXED
);

CREATE TABLE IF NOT EXISTS sections (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  heading TEXT,
  section_at TEXT,
  body TEXT NOT NULL,
  body_hash TEXT,
  ordinal INTEGER NOT NULL,
  token_estimate INTEGER,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plans (
  document_id TEXT PRIMARY KEY REFERENCES documents(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (
    status IN ('draft', 'backlog', 'in_queue', 'in_progress', 'done')
  ),
  name TEXT,
  overview TEXT,
  project TEXT,
  linear_task_id TEXT,
  todo_total INTEGER NOT NULL DEFAULT 0,
  todo_done INTEGER NOT NULL DEFAULT 0,
  status_changed_at TEXT
);

CREATE TABLE IF NOT EXISTS stakeholders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  organization TEXT,
  role TEXT,
  influence_level TEXT CHECK(influence_level IN ('low','medium','high','critical')) DEFAULT 'medium',
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS team_members (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  capacity_level TEXT CHECK(capacity_level IN ('full_time','part_time','qa','ops_dev','external','unknown')) DEFAULT 'unknown',
  skills_json TEXT,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS execution_items (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  repo_group_id TEXT,
  source_document_id TEXT,
  linear_task_id TEXT,
  title TEXT NOT NULL,
  objective TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN (
    'draft','needs_clarification','ready','in_progress','blocked',
    'qa_ready','done','deferred','rejected'
  )) DEFAULT 'draft',
  tier TEXT CHECK(tier IN ('micro','standard','full')) DEFAULT 'standard',
  owner_team_member_id TEXT,
  stakeholder_id TEXT,
  priority TEXT CHECK(priority IN ('low','normal','high','critical')) DEFAULT 'normal',
  risk_level TEXT CHECK(risk_level IN ('low','medium','high','critical')) DEFAULT 'medium',
  frontend_touched INTEGER NOT NULL DEFAULT 0,
  backend_touched INTEGER NOT NULL DEFAULT 0,
  database_touched INTEGER NOT NULL DEFAULT 0,
  auth_touched INTEGER NOT NULL DEFAULT 0,
  external_service_touched INTEGER NOT NULL DEFAULT 0,
  assumptions_json TEXT,
  non_goals_json TEXT,
  acceptance_criteria_json TEXT,
  qa_steps_json TEXT,
  dod_json TEXT,
  bloat_score INTEGER,
  metadata_json TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (repo_group_id) REFERENCES repo_groups(id),
  FOREIGN KEY (source_document_id) REFERENCES documents(id),
  FOREIGN KEY (owner_team_member_id) REFERENCES team_members(id),
  FOREIGN KEY (stakeholder_id) REFERENCES stakeholders(id)
);

CREATE TABLE IF NOT EXISTS decisions (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  repo_group_id TEXT,
  stakeholder_id TEXT,
  execution_item_id TEXT,
  title TEXT NOT NULL,
  decision TEXT NOT NULL,
  rationale TEXT,
  status TEXT NOT NULL CHECK(status IN ('proposed','accepted','superseded','rejected')) DEFAULT 'proposed',
  source_path TEXT,
  superseded_by_id TEXT,
  decided_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (execution_item_id) REFERENCES execution_items(id)
);

CREATE TABLE IF NOT EXISTS source_references (
  id TEXT PRIMARY KEY,
  target_type TEXT NOT NULL CHECK(target_type IN ('execution_item','decision','document','section')),
  target_id TEXT NOT NULL,
  source_type TEXT NOT NULL CHECK(source_type IN ('file','linear','chat','commit','url','manual')),
  source_path TEXT,
  source_label TEXT,
  quote TEXT,
  confidence TEXT CHECK(confidence IN ('low','medium','high')) DEFAULT 'medium',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS file_references (
  id TEXT PRIMARY KEY,
  execution_item_id TEXT NOT NULL,
  repo_id TEXT,
  file_path TEXT NOT NULL,
  reference_type TEXT CHECK(reference_type IN ('scope','frontend','backend','database','qa','risk','unknown')) DEFAULT 'unknown',
  exists_at_index_time INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (execution_item_id) REFERENCES execution_items(id)
);

CREATE TABLE IF NOT EXISTS index_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type TEXT NOT NULL,
  path TEXT,
  status TEXT NOT NULL CHECK(status IN ('ok','warning','error')),
  message TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_documents_kind_project ON documents(kind, project);
CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents(updated_at);
CREATE INDEX IF NOT EXISTS idx_execution_status ON execution_items(status);
CREATE INDEX IF NOT EXISTS idx_execution_repo_group ON execution_items(repo_group_id);
CREATE INDEX IF NOT EXISTS idx_execution_linear ON execution_items(linear_task_id);
CREATE INDEX IF NOT EXISTS idx_decisions_status ON decisions(status);
CREATE INDEX IF NOT EXISTS idx_file_references_path ON file_references(file_path);
CREATE INDEX IF NOT EXISTS idx_sections_document ON sections(document_id);
CREATE INDEX IF NOT EXISTS idx_plans_status ON plans(status);
