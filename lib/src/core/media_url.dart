// Media helpers now live with the rest of the configuration so the API host is
// defined in exactly one place. This file is kept as a re-export so existing
// imports keep working.
export 'app_config.dart'
    show kApiBase, kMediaOrigin, kServerOrigin, resolveMediaUrl;
