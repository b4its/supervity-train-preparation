-- Additional table for task tracking (replaces Jira)
CREATE TABLE IF NOT EXISTS action_tasks (
    id              SERIAL PRIMARY KEY,
    case_key        TEXT UNIQUE NOT NULL,
    task_type       TEXT DEFAULT 'procurement_action',
    summary         TEXT,
    description     TEXT,
    assignee        TEXT DEFAULT 'procurement_owner',
    priority        TEXT DEFAULT 'Medium',
    status          TEXT DEFAULT 'pending',
    decision        TEXT,
    reviewer        TEXT,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_action_tasks_case_key ON action_tasks(case_key);
CREATE INDEX idx_action_tasks_status   ON action_tasks(status);
