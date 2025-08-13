#!/bin/bash
set -e

# Puerto (Render da $PORT)
PORT=${PORT:-80}

# Ajustar Apache para escuchar en $PORT
if grep -q "^Listen " /etc/apache2/ports.conf; then
  sed -ri "s/Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf
else
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

# Crear configuración de OTRS para Apache
if [ -f /opt/otrs/scripts/apache2-httpd.include.conf ]; then
  cp /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/otrs.conf

  # Ajustar VirtualHost al puerto dinámico
  sed -ri "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" /etc/apache2/sites-available/otrs.conf

  # Asegurar que el DocumentRoot esté definido
  if ! grep -q "DocumentRoot" /etc/apache2/sites-available/otrs.conf; then
    echo "DocumentRoot /opt/otrs/bin/cgi-bin" >> /etc/apache2/sites-available/otrs.conf
  fi

  a2ensite otrs || true
fi

# Habilitar módulos de Apache
a2enmod perl cgi rewrite headers expires deflate || true

# Configurar permisos
if [ -f /opt/otrs/bin/otrs.SetPermissions.pl ]; then
  /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data || true
fi

# Iniciar cron (para trabajos de OTRS)
service cron start || true

# Arrancar Apache en primer plano
exec apache2ctl -D FOREGROUND
