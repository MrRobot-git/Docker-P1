#!/bin/bash
# Script de inicialización (se ejecuta en cada arranque, es idempotente).
# La imagen de Bitnami fija WP_HOME/WP_SITEURL en http://<host>/ sin puerto.
# Aquí los forzamos a la URL pública real (https + puerto) y hacemos que
# WordPress detecte HTTPS cuando https-portal envía X-Forwarded-Proto.
# https-portal reenvía Host sin puerto, y eso provocaría un bucle de redirecciones
# canónicas; por eso se fija también HTTP_HOST con el puerto público.
set -e
CONF=/bitnami/wordpress/wp-config.php
TMP="$(mktemp -p /bitnami/wordpress)"

# Solo actuamos si todavía está la configuración original de Bitnami
if grep -q "'http://' \. \$_SERVER\['HTTP_HOST'\]" "${CONF}"; then
  sed \
    -e "s|^define( 'WP_HOME'.*|define( 'WP_HOME', '${WORDPRESS_PUBLIC_URL}/' );|" \
    -e "s|^define( 'WP_SITEURL'.*|define( 'WP_SITEURL', '${WORDPRESS_PUBLIC_URL}/' );|" \
    -e "/That's all, stop editing/i if ( isset( \$_SERVER['HTTP_X_FORWARDED_PROTO'] ) \&\& 'https' === \$_SERVER['HTTP_X_FORWARDED_PROTO'] ) { \$_SERVER['HTTPS'] = 'on'; }\n\$_SERVER['HTTP_HOST'] = '${WORDPRESS_PUBLIC_URL#https://}';\n" \
    "${CONF}" > "${TMP}"
  # wp-config.php queda en solo lectura: se sustituye el fichero entero
  mv -f "${TMP}" "${CONF}"
  chmod 664 "${CONF}"
else
  rm -f "${TMP}"
fi
