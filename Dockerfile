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

# 2) descargar OTRS (source) y descomprimir en /opt/otrs
RUN wget -q https://ftp.otrs.org/pub/otrs/otrs-${OTRS_VERSION}.tar.bz2 -O /tmp/otrs.tar.bz2 \
    && mkdir -p /opt \
    && tar -xjf /tmp/otrs.tar.bz2 -C /opt \
    && mv /opt/otrs-${OTRS_VERSION} /opt/otrs \
    && rm /tmp/otrs.tar.bz2

# 3) crear usuario y permisos iniciales
RUN useradd -r -m -d /opt/otrs -c "OTRS user" otrs \
    && usermod -a -G www-data otrs \
    && chown -R otrs:www-data /opt/otrs

# 4) configurar apache (dejamos que entrypoint ajuste el puerto)
RUN a2enmod perl rewrite headers expires deflate

# 5) copiar entrypoint y dar permisos
COPY entrypoint.sh /opt/otrs/entrypoint.sh
RUN chmod +x /opt/otrs/entrypoint.sh

# 6) exponer puerto por defecto (Render pasará $PORT)
EXPOSE 80

# 7) arrancar entrypoint
CMD ["/opt/otrs/entrypoint.sh"]
