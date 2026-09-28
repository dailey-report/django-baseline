#!/bin/bash
set -euo pipefail
mkdir --parents /opt/app/logs

# one service owns schema setup; services sharing this image would race on a cold start.
# manage.py is absent until the django project is created.
if [ "${RUN_MIGRATIONS:-false}" = "true" ] && [ -f manage.py ]; then
    python manage.py migrate --noinput
    python manage.py collectstatic --noinput

    # create superuser if credentials are provided and no superuser exists yet
    if [ -n "${DJANGO_SUPERUSER_EMAIL:-}" ]; then
        python manage.py create_superuser_prn
    fi
fi

exec "$@"
