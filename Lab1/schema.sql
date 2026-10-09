DROP TABLE IF EXISTS task_comments CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS sprints CASCADE;
DROP TABLE IF EXISTS project_members CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE IF NOT EXISTS users (
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(255) UNIQUE NOT NULL,
    first_name    VARCHAR(255) NOT NULL,
    last_name     VARCHAR(255) NOT NULL,
    email         VARCHAR(255) UNIQUE NOT NULL,
    position      VARCHAR(20) NOT NULL DEFAULT 'developer'
        CHECK (position IN ('leader', 'manager', 'developer', 'qa', 'designer')),
    organization  VARCHAR(255),
    location      VARCHAR(255),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS projects (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(255) NOT NULL,
    description  TEXT,
    owner_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status       VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('planning', 'active', 'hold', 'completed', 'cancelled')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_members (
    project_id  BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id     BIGINT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    role        VARCHAR(20) NOT NULL DEFAULT 'member'
        CHECK (role IN ('member', 'admin')),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, user_id)
);

CREATE TABLE IF NOT EXISTS sprints (
    id          BIGSERIAL PRIMARY KEY,
    project_id  BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    start_date  TIMESTAMPTZ NOT NULL,
    end_date    TIMESTAMPTZ NOT NULL
        CHECK (end_date > start_date),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS tasks (
    id           BIGSERIAL PRIMARY KEY,
    project_id   BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    sprint_id    BIGINT REFERENCES sprints(id) ON DELETE SET NULL,
    title        VARCHAR(255) NOT NULL,
    description  TEXT,
    assignee_id  BIGINT REFERENCES users(id) ON DELETE SET NULL,
    reporter_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status       VARCHAR(20) NOT NULL DEFAULT 'todo'
        CHECK (status IN ('planning', 'todo', 'in_progress', 'in_review',
                          'in_testing', 'ready_to_deploy', 'done', 'cancelled')),
    priority     VARCHAR(20) NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS task_comments (
    id          BIGSERIAL PRIMARY KEY,
    task_id     BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id     BIGINT REFERENCES users(id) ON DELETE SET NULL,
    comment     TEXT NOT NULL
        CHECK (comment != ''),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);