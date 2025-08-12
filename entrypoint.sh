#!/bin/bash
set -e

# Si Render proporciona $PORT, úsalo; si no, default 80
PORT=${PORT:-80}

# Ajustar Apache para escuchar en $PORT
if grep -q "^Listen " /etc/apache2/ports.conf; then
  sed -ri "s/Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf
else
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

# Ajustar VirtualHost (*) si existe configuración default o la de otrs
for f in /etc/apache2/sites-available/*.conf; do
  [ -f "$f" ] && sed -ri "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" "$f" || true
done

# Habilitar site de OTRS si existe el include de OTRS
if [ -f /opt/otrs/scripts/apache2-httpd.include.conf ]; then
  cp /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/otrs.conf
  a2ensite otrs || true
fi

# Permisos (intenta ser idempotente)
if [ -f /opt/otrs/bin/otrs.SetPermissions.pl ]; then
  /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data || true
fi

# Iniciar cron en background (OTRS usa cron jobs)
service cron start || true

# Arrancar Apache en primer plano
exec apache2ctl -D FOREGROUND
