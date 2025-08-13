#!/bin/bash
set -e

PORT=${PORT:-80}
# Definir ServerName para evitar warnings
if ! grep -q "^ServerName" /etc/apache2/apache2.conf; then
  echo "ServerName localhost" >> /etc/apache2/apache2.conf
fi

# Ajustar Apache Listen
if grep -q "^Listen " /etc/apache2/ports.conf; then
  sed -ri "s/Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf
else
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

# Ajustar VirtualHost al puerto dinámico
for f in /etc/apache2/sites-available/*.conf; do
  [ -f "$f" ] && sed -ri "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" "$f" || true
done

# Permisos OTRS
if [ -f /opt/otrs/bin/otrs.SetPermissions.pl ]; then
  /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data || true
fi

# Iniciar cron
service cron start || true

# Arrancar Apache en primer plano
exec apache2ctl -D FOREGROUND
