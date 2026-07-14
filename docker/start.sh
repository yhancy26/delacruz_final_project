# Create this file: docker/start.sh
#!/usr/bin/env bash
set -e


PORT_TO_USE=${PORT:-80}
sed -i "s/Listen 80/Listen ${PORT_TO_USE}/" /etc/apache2/ports.conf
sed -i "s/:80/:${PORT_TO_USE}/" /etc/apache2/sites-available/000-default.conf


php artisan storage:link || true
php artisan db:seed || true
php artisan migrate --force || true
php artisan optimize || true


exec apache2-foreground





