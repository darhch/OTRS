# Dockerfile (otrs-render/Dockerfile)
FROM ubuntu:22.04

ENV OTRS_VERSION=6.0.34
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# 1) instalar dependencias del sistema y módulos Perl comunes
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
    libtemplate-perl \
    libsoap-lite-perl \
    libarchive-zip-perl \
    libio-socket-ssl-perl \
    libauthen-sasl-perl \
    libgd-perl \
    libxml-simple-perl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# 2) crear usuario y permisos iniciales
RUN useradd -r -m -d /opt/otrs -c "OTRS user" otrs \
    && usermod -a -G www-data otrs \
    && chown -R otrs:www-data /opt/otrs

# 3) descomprimir archivo OTRS en /opt/otrs
# Instalacion de BZIP2 para que pueda descomprimir la app
RUN apt-get update && apt-get install -y bzip2 && rm -rf /var/lib/apt/lists/*

COPY otrs-community-edition-6.0.34.tar.bz2 /tmp/otrs-community-edition-6.0.34.tar.bz2

RUN mkdir -p /opt \
    && tar -xjf /tmp/otrs-community-edition-6.0.34.tar.bz2 -C /opt \
    && ls -l /opt/otrs-community-edition-6.0.34/var/httpd/ \
    && mv /opt/otrs-community-edition-6.0.34 /opt/otrs \
    && rm /tmp/otrs-community-edition-6.0.34.tar.bz2 \
    && chown -R otrs:www-data /opt/otrs \
    && chmod -R 750 /opt/otrs \
    && chmod -R 755 /opt/otrs/var/httpd/htdocs
	


# 4) configurar apache (dejamos que entrypoint ajuste el puerto)
RUN a2enmod perl rewrite headers expires deflate cgid

RUN echo '<VirtualHost *:80>\n\
    ServerName localhost\n\
   DocumentRoot /opt/otrs/var/httpd/htdocs\n\
<Directory /opt/otrs/var/httpd/htdocs>\n\
    AllowOverride All\n\
    Options +FollowSymLinks\n\
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

# 5) copiar entrypoint y dar permisos
COPY entrypoint.sh /opt/otrs/entrypoint.sh
RUN chmod +x /opt/otrs/entrypoint.sh

# 6) exponer puerto por defecto (Render pasará $PORT)
EXPOSE 80

# 7) arrancar entrypoint
CMD ["/opt/otrs/entrypoint.sh"]
