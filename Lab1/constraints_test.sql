\set ON_ERROR_STOP 0

--  duplicate key value violates unique constraint "users_username_key"
INSERT INTO users (username, first_name, last_name, email)
VALUES ('leader', 'Дубль', 'Дублёв', 'dup1@corp.com');

-- duplicate key value violates unique constraint "users_email_key"
INSERT INTO users (username, first_name, last_name, email)
VALUES ('newuser', 'Новый', 'Юзер', 'leader@corp.com');


-- new row for relation "users" violates check constraint "users_position_check"
INSERT INTO users (username, first_name, last_name, email, position)
VALUES ('badpos', 'Тест', 'Тестов', 'badpos@corp.com', 'ceo');

-- new row for relation "projects" violates check constraint "projects_status_check"
INSERT INTO projects (name, owner_id, status)
VALUES ('Bad Project', 1, 'frozen');

-- new row for relation "sprints" violates check constraint "sprints_end_date_check"
INSERT INTO sprints (project_id, name, start_date, end_date)
VALUES (1, 'reversed', '2026-10-10 00:00:00+00', '2026-10-01 00:00:00+00');


-- duplicate key value violates unique constraint
INSERT INTO sprints (project_id, name, start_date, end_date)
VALUES (1, 'develop', '2026-10-01 00:00:00+00', '2026-10-10 00:00:00+00');


-- duplicate key value violates unique constraint
INSERT INTO project_members (project_id, user_id, role)
VALUES (1, 2, 'member');

--  new row for relation "task_comments" violates check constraint
INSERT INTO task_comments (task_id, user_id, comment)
VALUES (1, 1, '');

-- insert or update on table "tasks" violates foreign key constraint
INSERT INTO tasks (project_id, title, reporter_id)
VALUES (1, 'Тестовая задача', 999);

-- update or delete on table "users" violates foreign key constraint
DELETE FROM users WHERE id = 1;

-- new row for relation "tasks" violates check constraint
UPDATE tasks SET status = 'unknown' WHERE id = 1;

-- duplicate key value violates unique constraint
UPDATE users SET email = 'leader@corp.com' WHERE id = 2;