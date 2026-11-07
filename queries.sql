-- 1.2.1 Добавление новой сущности и связанных с ней записей с помощью INSERT.
WITH new_task AS (
    INSERT INTO tasks (sprint_id, title, description, owner_id, status, priority)
    VALUES (5, 'Исправить восстановление пароля', 'Повторная отправка письма делает предыдущую ссылку недействительной без предупреждения пользователя', 1, 'todo', 'high')
    RETURNING id
), new_member AS (
    INSERT INTO task_members (task_id, assignee_id, reporter_id)
    VALUES ((SELECT id FROM new_task), 1, 2)
)
INSERT INTO task_comments (task_id, user_id, comment)
VALUES ((SELECT id FROM new_task), 2, 'Ошибка воспроизводится при двух последовательных запросах восстановления пароля')


-- 1.2.2 Изменение состояния существующей операции через UPDATE.
UPDATE tasks SET status = 'in_progress', updated_at = NOW() WHERE id = (SELECT id FROM tasks WHERE sprint_id = 5 AND status = 'todo' ORDER BY id DESC LIMIT 1) AND status = 'todo';

-- 1.2.3 Массовое изменение нескольких записей по содержательному условию.
UPDATE tasks SET status = 'in_review', updated_at = NOW() WHERE sprint_id = 5 AND status = 'in_progress';

-- 1.2.4 Удаление записи с помощью DELETE с учётом существующих ограничений целостности.
DELETE FROM task_comments WHERE task_id = (SELECT id FROM tasks WHERE sprint_id = 5 AND status = 'in_review' ORDER BY id DESC LIMIT 1);

-- 1.2.5 Демонстрацию отмены изменений с помощью ROLLBACK
BEGIN;
UPDATE tasks SET status = 'in_testing', updated_at = NOW() WHERE sprint_id = 5 AND status = 'in_review';
ROLLBACK;

-- 2.1 Многотабличные запросы

SELECT t.id as 'id', t.title as "task title",  t.status, t.priority, s.name as "sprint name", p.name as "project name", u.first_name as "assignee name"
FROM tasks t
LEFT JOIN sprints s ON t.sprint_id = s.id
LEFT JOIN projects p ON s.project_id = p.id
LEFT JOIN task_members tm ON t.id = tm.task_id
LEFT JOIN users u ON tm.assignee_id = u.id

SELECT t.id as 'id', t.title as "task title", t.status, u.first_name as "assignee name"
FROM tasks t
LEFT JOIN task_members tm ON t.id = tm.task_id
LEFT JOIN users u ON tm.assignee_id = u.id
LEFT JOIN task_comments tc ON t.id = tc.task_id
WHERE tc.id IS NULL

SELECT t.id as 'id', t.title as "task title", t.status, s.name as "sprint name", p.name as "project name"
FROM tasks t
JOIN sprints s ON t.sprint_id = s.id
JOIN projects p ON s.project_id = p.id
WHERE p.status = 'active' AND t.priority = 'high' AND s.start_date >= '2026-11-01' AND s.end_date <= '2026-12-01' AND t.status IN ('in_review', 'in_progress')
ORDER BY p.id, t.id;

-- 2.2 Агрегация и группировка

SELECT p.id, p.name, t.status, COUNT(t.id) as "task count"
FROM projects p
LEFT JOIN sprints s ON p.id = s.project_id
LEFT JOIN tasks t ON s.id = t.sprint_id
GROUP BY p.id, t.status;

SELECT p.name, COUNT(t.id) as "task count", AVG(EXTRACT(EPOCH FROM (t.updated_at - t.created_at))) as "avg duration", MAX(EXTRACT(EPOCH FROM (t.updated_at - t.created_at))) as "max duration", MIN(EXTRACT(EPOCH FROM (t.updated_at - t.created_at))) as "min duration"
FROM projects p
LEFT JOIN sprints s ON p.id = s.project_id
LEFT JOIN tasks t ON s.id = t.sprint_id
WHERE t.status = 'done'
GROUP BY p.id
HAVING AVG(EXTRACT(EPOCH FROM (t.updated_at - t.created_at))) / 3600 > 20;

SELECT
    EXTRACT(MONTH FROM t.created_at) as month,
    EXTRACT(YEAR FROM t.created_at) as year,
    COUNT(t.id) as all_tasks,
    COUNT(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as done,
    COUNT(CASE WHEN t.status = 'cancelled' THEN 1 ELSE 0 END) as cancelled,
    SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(t.id) AS done_percentage
FROM tasks t
GROUP BY year, month
ORDER BY year, month ASC;

-- 3.1 Сравнение с вычисляемым показателем

WITH task_stats AS (
    SELECT s.id AS sprint_id, t.id AS task_id, t.title, COUNT(tc.id) as comment_count
    FROM tasks t
    LEFT JOIN task_comments tc ON t.id = tc.task_id
    JOIN sprints s ON t.sprint_id = s.id
    GROUP BY s.id, t.id
), avg_count AS (
    SELECT sprint_id, AVG(comment_count) as avg_comment_count
    FROM task_stats
    GROUP BY sprint_id
)
SELECT ts.sprint_id, ts.task_id, ts.title, ts.comment_count, ac.avg_comment_count
FROM task_stats ts
JOIN avg_count ac ON ts.sprint_id = ac.sprint_id
WHERE ts.comment_count > ac.avg_comment_count;

-- 3.2  Проверка существования связанных данных

SELECT t.id, t.title, t.status, u.first_name as reporter_name, u.last_name as reporter_surname
FROM tasks t
LEFT JOIN task_members tm ON t.id = tm.task_id
LEFT JOIN users u ON tm.reporter_id = u.id
WHERE EXISTS (
    SELECT 1
    FROM task_comments tc
    WHERE tc.task_id = t.id AND tc.user_id = tm.reporter_id
);

-- 3.3 Поиск отсутствующих событий

SELECT t.id, t.title, t.status, u.first_name as assignee_name, u.last_name as assignee_surname
FROM tasks t
LEFT JOIN task_members tm ON t.id = tm.task_id
LEFT JOIN users u ON tm.assignee_id = u.id
WHERE t.status = 'in_progress' AND tm.assignee_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM task_comments tc
    WHERE tc.task_id = t.id AND tc.user_id = tm.assignee_id
);

-- 3.4 Коррелированный подзапрос

SELECT t.id, t.title, t.status, (
        SELECT COUNT(child.id)
        FROM task_parent pt
        JOIN tasks child ON pt.task_id = child.id
        WHERE pt.parent_id = t.id
          AND child.status NOT IN ('done', 'cancelled')
    ) AS unready_count
FROM tasks t;


-- 4. Комплексный аналитический отчёт с использованием CTE

WITH task_meta AS (
    SELECT
        p.id AS project_id,
        t.id AS task_id,
        t.status,
        tm.assignee_id AS assignee_id
    FROM tasks t
    JOIN sprints s ON t.sprint_id = s.id
    JOIN projects p ON s.project_id = p.id
    LEFT JOIN task_members tm ON t.id = tm.task_id
),
task_metrics AS (
    SELECT
        tmeta.project_id,
        tmeta.task_id,
        CASE
            WHEN tmeta.status = 'done' THEN 1
            ELSE 0
        END AS is_done,
        CASE
            WHEN tmeta.status = 'cancelled' THEN 1
            ELSE 0
        END AS is_cancelled,
        CASE
            WHEN tmeta.status NOT IN ('done', 'cancelled')
                 AND tmeta.assignee_id IS NULL
            THEN 1
            ELSE 0
        END AS need_attention,
        CASE
            WHEN tmeta.status NOT IN ('done', 'cancelled')
                 AND tmeta.assignee_id IS NOT NULL
                 AND NOT EXISTS (
                     SELECT 1
                     FROM task_comments tc
                     WHERE tc.task_id = tmeta.task_id
                       AND tc.user_id = tmeta.assignee_id
                 )
            THEN 1
            ELSE 0
        END AS need_feedback
    FROM task_meta tmeta
)
SELECT
    p.id,
    p.name,
    p.status,
    COUNT(tmeta.task_id) AS total_tasks,
    COALESCE(SUM(tmeta.is_done), 0) AS done_tasks,
    COALESCE(SUM(tmeta.is_cancelled), 0) AS cancelled_tasks,
    COALESCE(SUM(tmeta.need_attention), 0) AS tasks_needing_attention,
    COALESCE(SUM(tmeta.need_feedback), 0) AS tasks_needing_feedback,
    COALESCE(SUM(tmeta.is_done), 0) * 100.0
        / NULLIF(
            COUNT(tmeta.task_id) - COALESCE(SUM(tmeta.is_cancelled), 0),
            0
        ) AS done_percentage,
    CASE
        WHEN COUNT(tmeta.task_id) = 0 THEN 'Нет задач'
        WHEN COALESCE(SUM(tmeta.need_attention), 0) > 0
          OR COALESCE(SUM(tmeta.need_feedback), 0) > 0
            THEN 'Есть задачи, требующие внимания'
        ELSE 'Все задачи в порядке'
    END AS signal
FROM projects p
LEFT JOIN task_metrics tmeta ON p.id = tmeta.project_id
GROUP BY p.id
ORDER BY p.id;