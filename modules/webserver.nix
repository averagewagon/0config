{
  ...
}:

{
  # Caddy itself is installed via dnf and runs as the `caddy` system user so it
  # can bind 80/443. This module only owns the Caddyfile content; the system
  # service reads it via a one-time symlink at /etc/caddy/Caddyfile -> here.
  home.file.".config/caddy/Caddyfile".text = ''
    {
      email contact@joni.site
      admin off
    }

    joni.site {
      root * /home/jhen/sites/joni.site
      file_server {
        precompressed br gzip
      }
      encode zstd gzip
      header {
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        Cache-Control "public, max-age=3600"
      }
    }

    www.joni.site {
      redir https://joni.site{uri} permanent
    }
  '';
}
