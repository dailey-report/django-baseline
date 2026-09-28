Baseline Django for Rapid Start
===============================

# To Use for New Project

Dockerfile uses python docker image (simple tag for debian): https://hub.docker.com/_/python/

For these instructions, substitute 'baseline' with [your-project-name].  Clone into directory
[your-project-name].  Substitute [your-project-name] for directories referenced as baseline/
in these instructions.

1. New project as working directory: `cd baseline/`
1. Copy compose override: `cp artifacts/compose.override.yaml compose.override.yaml`
1. Edit both compose files and replace 'baseline' with [your-project-name]
1. Create environment file: `cp artifacts/env.example .env`
1. Edit .env with your values (passwords, secret key, `id -u` / `id -g` for CONTAINER_UID/GID)
1. `mkdir django_root`
1. Build in baseline/: `docker compose build`
1. Run a container shell: `docker compose run --rm baseline bash`
1. Create project using [MikeD Directory Structure](#miked-directory-structure): `django-admin startproject core . && django-admin startapp baseline`
1. Exit container shell
1. Add baseline modules to the generated package (celery, logging, request-id middleware,
test runner, superuser command): `cp --recursive artifacts/core/. django_root/core/`
1. Apply baseline customizations to the generated settings.py and urls.py:
`patch --directory=django_root --strip=0 < artifacts/core.patch`. A hunk reported "with fuzz"
applied; a failed one lands in `*.rej`: merge it by hand, and refresh the patch (see
[Maintaining core.patch](#maintaining-corepatch))
1. Replace 'baseline' with [your-project-name] in django_root/core/settings.py, and add the
new app to INSTALLED_APPS and the per-app loggers
1. Install commit hooks: `pre-commit install` (host, once per clone; `pipx install pre-commit`)
1. First-time format; the first pass rewrites django's generated files, the second confirms
clean: `./lint || ./lint`
1. Use compose to build and run all containers: `docker compose up`
1. Shell into main container: `docker compose exec baseline bash`

The `baseline` service runs migrations and collectstatic on start (`RUN_MIGRATIONS`); other
services sharing the image skip them. If `DJANGO_SUPERUSER_EMAIL` and
`DJANGO_SUPERUSER_PASSWORD` are set in `.env`, a superuser is created on first start.

Services: `baseline` (django), `celery-worker`, `celery-beat`, `postgres`, `rabbitmq` (celery
broker, management UI on 127.0.0.1:15672 in dev), `redis` (celery results, django cache).

# Notes

Be aware, .gitignore, .editorconfig, .pre-commit-config.yaml, and pyproject.toml are included
in the repo, so they may need to be edited for the new project.

## MikeD Directory Structure
Substitute 'baseline' with [new-project-name] in these instructions. In container /opt/app:
```bash
django-admin startproject core .
django-admin startapp baseline
```

now repo structure on host is
```text
baseline/                 (container artifacts)
  /django_root            (django project root)
  /django_root/core       (top-level package, configuration, users, etc)
  /django_root/baseline/  (this is where the magic is)
```

## Production Release

Development tracks the latest stable python (`python:3-trixie`). When the project is ready for
production release, pin the Dockerfile to the python minor version it was released with (e.g.
`python:3.14-trixie`), so rebuilds take patch releases only.

## Formatting and Linting

[ruff](https://docs.astral.sh/ruff/) formats and lints; configuration is in `pyproject.toml`.
Line length 94, single quotes, `"""` docstrings, isort sections with django separate.

`./lint` checks the whole tree. The commit hook runs the same checks on staged files, and CI
must run `./lint`: a hook can be skipped with `--no-verify`.

## Check Code Test Coverage
```bash
docker compose exec baseline bash -c "coverage run --source='.' manage.py test"
docker compose exec baseline bash -c "coverage report"
```

## Graph Primary Models
```bash
./manage.py graph_models --output models.png core baseline
```

## Generate API Schema
Served at `/api/schema/` and browsable at `/api/docs/`. To write it to a file:
```bash
# in baseline container
./manage.py spectacular --validate --file baseline-api-openapi.yml
```

## Maintaining core.patch

`artifacts/core.patch` is a diff against the settings.py and urls.py that `startproject`
generates. When it stops applying cleanly, regenerate it against the current Django. Generate in
the app image: django formats startproject output with black when it finds one, so a host run
differs.
```bash
mkdir /tmp/gen && docker run --rm --user "$(id -u):$(id -g)" --volume /tmp/gen:/gen \
    baseline:latest django-admin startproject core /gen
cp --recursive /tmp/gen /tmp/custom
patch --directory=/tmp/custom --strip=0 < artifacts/core.patch   # then fix by hand
(cd /tmp && for f in settings urls; do
    diff --unified=2 --label core/$f.py --label core/$f.py gen/core/$f.py custom/core/$f.py
done) > artifacts/core.patch
```
Context stays at 2 lines: the generated SECRET_KEY is random, so no hunk may reach it.


## Generate Documentation with Sphinx

Execute these instructions within a container shell.

Install required packages:
```bash
python3 -m pip install sphinx sphinx-autobuild sphinx_rtd_theme
```

In django_root, create docs dir and configure Sphinx from `artifacts/example-sphinx-conf.py`:
```bash
mkdir --parents docs/source
vi docs/source/conf.py
```

In docs dir, Autogenerate .rst files:
```bash
sphinx-apidoc -o source ../django_root/
```

Add modules to toctree:
```bash
vi source/index.rst
```
