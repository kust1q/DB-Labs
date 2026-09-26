INSERT INTO users (username, first_name, last_name, email, position, organization, location) VALUES
('leader', 'Игорь', 'Волков', 'leader@corp.com', 'leader', 'Corp', 'Москва'),
('manager', 'Мария', 'Соколова',  'manager@corp.com',  'manager',   'Corp', 'Москва'),
('dev', 'Дмитрий', 'Орлов', 'dev@corp.com', DEFAULT, 'Corp', 'Санкт-Петербург'),
('qa', 'Ольга', 'Кузнецова', 'qa@corp.com', 'qa', 'Corp', 'Казань'),
('designer', 'Артём', 'Морозов', 'designer@corp.com', 'designer', 'Corp', 'Новосибирск');

INSERT INTO projects (name, description, owner_id, status) VALUES
('Corp Portal', 'Основной корпоративный портал', 1, 'active'),
('CRM System', 'Внутренняя CRM', 2, 'planning'),
('Mobile App', 'Мобильное приложение', 3, 'hold'),
('Billing', 'Биллинг и платежи', 4, 'completed'),
('Legacy Cleanup','Списание устаревшего легаси', 5, 'cancelled');

INSERT INTO project_members (project_id, user_id, role) VALUES
(1, 2, 'member'),
(1, 3, 'member'),
(1, 4, 'member'),
(1, 5, 'member');

INSERT INTO sprints (project_id, name, start_date, end_date) VALUES
(1, 'develop', '2026-09-01 00:00:00+00', '2026-09-14 23:59:59+00'),
(1, 'bugs', '2026-09-15 00:00:00+00', '2026-09-28 23:59:59+00');

INSERT INTO tasks (project_id, sprint_id, title, description, assignee_id, reporter_id, status, priority) VALUES
-- sprint develop
(1, 1, 'Настроить CI/CD', 'Развернуть пайплайн сборки и деплоя', 3, 1, 'planning', 'high'),
(1, 1, 'Обновить README', NULL, NULL, 1, 'todo', 'low'),
(1, 1, 'Реализовать авторизацию', 'JWT + refresh-токены, интеграция с SSO', 3, 2, 'in_progress', 'high'),
(1, 1, 'Код-ревью API', 'Проверить MR 142 по эндпоинтам', 4, 2, 'in_review', 'medium'),
(1, 2, 'Написать тесты на логин', NULL, 5, 4, 'in_testing', 'medium'),
(1, 2, 'Подготовить релиз 1.0', 'Собрать changelog, обновить версии', 3, 1, 'ready_to_deploy', 'high'),
(1, 2, 'Обновить дизайн главной', 'Новая цветовая схема и типографика', 5, 3, 'done', 'low'),
(1, 2, 'Устаревшая задача по старому API', NULL, NULL, 5, 'cancelled', 'low');

INSERT INTO task_comments (task_id, user_id, comment) VALUES
(1, 1, 'Начни с GitHub Actions, у нас уже есть шаблон в другом репо'),
(1, 3, 'Ок, беру в работу. К среде будет первая версия'),
(3, 2, 'Важно: SSO должен работать и для внешних подрядчиков'),
(3, 3, 'Понял, добавлю отдельный realm'),
(4, 4, 'Проверил, нашёл пару замечаний по валидации'),
(4, 2, 'Спасибо, поправлю сегодня'),
(6, 1, 'Релиз согласован с бизнесом, можно готовить'),
(7, 5, 'Дизайн залит в Figma, ссылка в описании задачи');