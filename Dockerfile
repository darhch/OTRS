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
    bzip2 \
    && rm -rf /var/lib/apt/lists/*

# 2) crear usuario y permisos iniciales
RUN useradd -r -m -d /opt/otrs -c "OTRS user" otrs \
    && usermod -a -G www-data otrs \
    && chown -R otrs:www-data /opt/otrs

# 3) copiar y descomprimir OTRS
COPY otrs-community-edition-6.0.34.tar.bz2 /tmp/otrs.tar.bz2
RUN mkdir -p /opt \
    && tar -xjf /tmp/otrs.tar.bz2 -C /opt \
    && mv /opt/otrs-community-edition-6.0.34 /opt/otrs \
    && rm /tmp/otrs.tar.bz2

# 4) configurar apache (puerto fijo 80 aquí, se ajusta luego en entrypoint)
RUN a2enmod perl rewrite headers expires deflate
RUN echo '<VirtualHost *:80>\n\
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

# 5) copiar entrypoint y dar permisos
COPY entrypoint.sh /opt/otrs/entrypoint.sh
RUN sed -i 's/\r$//' /opt/otrs/entrypoint.sh && chmod +x /opt/otrs/entrypoint.sh


# 6) exponer puerto por defecto
EXPOSE 80

# 7) arrancar entrypoint
CMD ["/opt/otrs/entrypoint.sh"]
