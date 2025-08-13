#!/bin/bash
set -e
chown -R www-data:www-data /opt/otrs/var/httpd
chmod -R 755 /opt/otrs/var/httpd
PORT=${PORT:-80}

# Ajustar Apache para escuchar en el puerto dinámico de Render
if grep -q "^Listen " /etc/apache2/ports.conf; then
  sed -ri "s/Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf
else
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

# Ajustar VirtualHost para usar el puerto correcto
for f in /etc/apache2/sites-available/*.conf; do
  [ -f "$f" ] && sed -ri "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" "$f" || true
done

# Evitar warning ServerName
if ! grep -q "^ServerName" /etc/apache2/apache2.conf; then
  echo "ServerName localhost" >> /etc/apache2/apache2.conf
fi

# Establecer permisos OTRS (idempotente)
if [ -f /opt/otrs/bin/otrs.SetPermissions.pl ]; then
  /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data || true
fi

# Iniciar cron en background (necesario para OTRS)
service cron start || true

# Ejecutar Apache en primer plano
exec apache2ctl -D FOREGROUND
