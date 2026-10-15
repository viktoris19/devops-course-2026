## 9. Контейнеризация

- **Docker Engine:** установлен из официального репозитория download.docker.com, версия 29.9.1
- **Docker Compose:** плагин v2, установлен вместе с Docker (пакет docker-compose-plugin), версия v5.6.0
- **Участники группы docker:** пользователь `devops`
- **Расположение проекта на сервере:** `/home/devops/app/`
- **Расположение файла `.env`:** `/home/devops/app/.env`, права `600`, владелец `devops`
- **Публикуемые порты и адреса:** `127.0.0.1:5000` (только локально, для Nginx); порт 5432 (PostgreSQL) не публикуется — доступен только внутри Compose-сети `app_backend`
- **Именованные тома:** `app_db_data` (данные PostgreSQL)
- **Конфигурация обратного прокси-сервера:** `location /app/` в `/etc/nginx/sites-available/devops-site`, `proxy_pass http://127.0.0.1:5000/;`