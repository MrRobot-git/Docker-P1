# Docker – Práctica RA2

Tres proyectos Docker Compose independientes que pueden estar levantados a la vez (puertos distintos).

| Proyecto | Servicios | URLs |
|---|---|---|
| `1-wordpress/` | WordPress (Bitnami) + MySQL + phpMyAdmin + https-portal | https://localhost:8443 · http://localhost:8081 (redirige a HTTPS) · phpMyAdmin http://localhost:8082 |
| `2-prestashop/` | PrestaShop (oficial) + MySQL + phpMyAdmin + https-portal | https://localhost:9443 · http://localhost:8091 (redirige a HTTPS) · phpMyAdmin http://localhost:8092 |
| `3-web-node/` | Nginx + Node.js + MySQL | http://localhost:8100 |

El certificado HTTPS es autofirmado (modo `local` de https-portal): el navegador avisará; con curl usar `-k`.

## Preparación (una vez por proyecto)

```bash
cd <proyecto>
cp .env.example .env     # y edita las contraseñas si quieres
```
Los `.env` **no** se suben a git. Los `.env.example` llevan valores de ejemplo.

## Credenciales de prueba (valores del `.env` local de desarrollo)

Si copias `.env.example` tal cual, sustituye `cambia_*` por tus valores. Las credenciales usadas en las pruebas:

| Proyecto | Aplicación | phpMyAdmin / BD |
|---|---|---|
| WordPress | `admin` / `AdminWp_2026!` (`/wp-admin`) | `root` / `RootWp_2026!` · `wordpress_user` / `UserWp_2026!` |
| PrestaShop | `admin@example.com` / `AdminPs_2026!` (`/admin-dev`) | `root` / `RootPs_2026!` · `prestashop_user` / `UserPs_2026!` |
| Web Node | – | `root` / `RootNode_2026!` · `tienda_user` / `UserNode_2026!` |

> Son contraseñas de prueba solo para este laboratorio local. Para los valores reales de tu `.env` usa las que prefieras.

## Comandos

```bash
# Levantar (en cada carpeta)
docker compose up -d            # 3-web-node: añade --build la primera vez
docker compose ps               # estado / healthchecks
docker compose logs -f          # logs

# Parar
docker compose stop             # para sin borrar
docker compose down             # para y elimina contenedores (conserva datos)
docker compose down -v          # además borra volúmenes (reinicia desde cero)
```

PrestaShop tarda unos 2-3 minutos en el primer arranque (instalación automática). WordPress, ~1 minuto.

## Imágenes usadas

- **WordPress**: `bitnami/wordpress:latest` (sigue disponible en Docker Hub, por eso no hizo falta `bitnamilegacy/`).
- **PrestaShop**: `bitnami/prestashop` y `bitnamilegacy/prestashop` **no existen** en Docker Hub, así que se usa la imagen oficial `prestashop/prestashop:8` (la misma que usa el ejemplo del PDF).
- `mysql:8.0`, `phpmyadmin/phpmyadmin`, `steveltn/https-portal:1`, `nginx:1.27-alpine`, `node:20-alpine`.
- No se usa `seccomp:unconfined`: no apareció el error `mbind`.

## Decisiones clave de los docker-compose.yml

- **Redes**: `frontend-network` (https-portal, app, phpMyAdmin) y `backend-network` (MySQL). La app y phpMyAdmin están en ambas para poder llegar a MySQL; MySQL solo en backend y **sin `ports`**, así que no es accesible desde el host (comprobado: puertos 3306/33060 rechazan conexión).
- **Healthcheck** de MySQL: `mysqladmin ping -h 127.0.0.1` con la contraseña root. Se usa TCP en 127.0.0.1 porque el servidor temporal de inicialización solo escucha por socket, y así el estado `healthy` significa realmente "listo para conexiones". `start_period` evita falsos fallos durante la inicialización.
- **depends_on con `condition: service_healthy`**: app y phpMyAdmin esperan a MySQL healthy; https-portal espera a que WordPress/PrestaShop estén healthy (que también tienen healthcheck); en el proyecto 3, nginx espera a node y node a MySQL.
- **restart: unless-stopped** en todos los servicios: se reinician tras un fallo o reinicio del host, pero no si los paras a mano.
- **Puertos**: solo se publican https-portal (HTTP/HTTPS), phpMyAdmin y nginx; todos configurables desde `.env` y distintos entre proyectos.
- **Variables**: todo en `.env` (el compose solo usa `${...}`).
- **URL con puerto**: https-portal reenvía `Host` sin puerto y redirige HTTP→`https://localhost` (puerto 443), lo que rompe WordPress/PrestaShop con puertos no estándar (bucle de redirecciones). Soluciones:
  - redirección HTTP→HTTPS propia con el puerto correcto (`CUSTOM_NGINX_SERVER_PLAIN_CONFIG_BLOCK`);
  - WordPress: `init/wp-https.sh` fija `WP_HOME`/`WP_SITEURL` a `https://localhost:8443`, `HTTP_HOST` con puerto y detecta HTTPS por `X-Forwarded-Proto`;
  - PrestaShop: `PS_DOMAIN=localhost:9443` + `php/fix-host.php` (`auto_prepend_file`) que fija el host con puerto y HTTPS.
- **Proyecto 3**: `mysql-init/init.sql` (montado en `/docker-entrypoint-initdb.d`) crea la tabla `productos` con datos; el contenedor `node` (Express + mysql2, Dockerfile propio) la consulta y nginx hace de proxy inverso.
