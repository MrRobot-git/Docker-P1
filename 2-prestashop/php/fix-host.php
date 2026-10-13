<?php
// https-portal reenvía la cabecera Host sin puerto y PrestaShop redirigiría
// en bucle a https://localhost:9443. Se fija el host público (PS_DOMAIN, con
// puerto) y se marca la petición como HTTPS.
if (getenv('PS_DOMAIN')) {
    $_SERVER['HTTP_HOST'] = getenv('PS_DOMAIN');
}
if (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
