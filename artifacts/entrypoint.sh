#!/bin/bash
set -euo pipefail
mkdir --parents /opt/app/logs

[ -f manage.py ] && python manage.py migrate --noinput

# create superuser if not exist
# ...that is, if the one time CI/CD command is passing superuser credentials in environment
if [ -n "${DJANGO_SUPERUSER_EMAIL:-}" ]; then
    python manage.py create_superuser_prn
fi

exec "$@"
