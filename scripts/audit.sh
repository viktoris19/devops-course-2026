#!/usr/bin/env bash
# Аудит конфигурации сервера devops-vm
# Использование: ./audit.sh
set -uo pipefail

PASS=0; FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo " [OK] $desc"
        ((PASS++))
    else
        echo " [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"
        ((FAIL++))
    fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo " [1] Служба SSH"
check "Вход от имени root запрещён" "no" "$(sudo sshd -T | awk '/^permitrootlogin/{print $2}')"
check "Парольная аутентификация отключена" "no" "$(sudo sshd -T | awk '/^passwordauthentication/{print $2}')"
check "Порт SSH определён" "22" "$(sudo sshd -T | awk '/^port/{print $2}')"
check "MaxAuthTries = 3" "3" "$(sudo sshd -T | awk '/^maxauthtries/{print $2}')"

echo " [2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"
check "Политика по умолчанию — deny" "deny" "$(sudo ufw status verbose | awk '/^Default:/{print $2}')"

echo " [3] Учётные записи"
awk -F: '$3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd

echo " [4] Веб-сервер"
check "nginx конфигурация корректна" "0" "$(sudo nginx -t >/dev/null 2>&1; echo $?)"
check "Сертификат действует > 30 дней" "0" "$(openssl x509 -in /etc/ssl/certs/devops.crt -checkend 2592000 >/dev/null 2>&1; echo $?)"
check "Нет файлов с правом записи для всех" "0" "$(find /var/www/devops-site -perm -o+w 2>/dev/null | wc -l)"
check "Права ключа TLS = 600" "600" "$(sudo stat -c '%a' /etc/ssl/private/devops.key 2>/dev/null)"

echo " [5] Контейнеризация"
check "Служба docker активна" "active" "$(systemctl is-active docker)"
check "Контейнер СУБД healthy" "healthy" "$(docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null)"
check "Порты 5000 и 5432 только на 127.0.0.1" "0" "$(ss -tln | awk '$4 !~ /^127\.0\.0\.1:(5000|5432)$/ && $4 ~ /:(5000|5432)$/' | wc -l)"
check "Права .env = 600" "600" "$(stat -c '%a' ~/app/.env 2>/dev/null)"

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1