# Dockerfile (otrs-render/Dockerfile)
FROM ubuntu:22.04

ENV OTRS_VERSION=6.0.34
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# 1) Instalar dependencias del sistema y módulos Perl comunes
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    libapache2-mod-perl2 \
    wget \
    unzip \
    cron \
    ca-certificates \
    perl \
    libdbi-perl \
    libdbd-pg-perl \
    libdbd-mysql-perl \
    libtemplate-perl \
    libsoap-lite-perl \
    libarchive-zip-perl \
    libio-socket-ssl-perl \
    libauthen-sasl-perl \
    libgd-perl \
    libxml-simple-perl \
    postgresql-client \
    bzip2 \
    && rm -rf /var/lib/apt/lists/*

# 2) Crear usuario y permisos iniciales
RUN useradd -r -m -d /opt/otrs -c "OTRS user" otrs \
    && usermod -a -G www-data otrs \
    && chown -R otrs:www-data /opt/otrs

# 3) Copiar y descomprimir OTRS (el .tar.bz2 debe estar junto al Dockerfile)
COPY otrs-community-edition-${OTRS_VERSION}.tar.bz2 /tmp/otrs.tar.bz2
RUN mkdir -p /opt \
    && tar -xjf /tmp/otrs.tar.bz2 -C /opt \
    && mv /opt/otrs-community-edition-${OTRS_VERSION} /opt/otrs \
    && rm /tmp/otrs.tar.bz2

# 4) Configurar Apache (sin puerto fijo, el entrypoint lo ajustará)
RUN a2enmod perl rewrite headers expires deflate \
    && echo '<VirtualHost *:80>\n\
    ServerName localhost\n\
    DocumentRoot /opt/otrs\n\
    <Directory /opt/otrs>\n\
        AllowOverride All\n\
        Options +ExecCGI\n\
        AddHandler cgi-script .pl\n\
        Require all granted\n\
    </Directory>\n\
    ScriptAlias /otrs/ /opt/otrs/bin/cgi-bin/\n\
    <Directory /opt/otrs/bin/cgi-bin>\n\
        AllowOverride All\n\
        Options +ExecCGI\n\
        AddHandler cgi-script .pl\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/otrs.conf \
    && a2ensite otrs.conf \
    && a2dissite 000-default.conf

# 5) Copiar entrypoint y dar permisos
COPY entrypoint.sh /opt/otrs/entrypoint.sh
RUN chmod +x /opt/otrs/entrypoint.sh

# 6) Exponer puerto por defecto (Render usará $PORT en runtime)
EXPOSE 80

# 7) Arrancar entrypoint
CMD ["/opt/otrs/entrypoint.sh"]
