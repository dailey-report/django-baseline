Baseline Django for Rapid Start
===============================

# To Use for New Project

Dockerfile uses python docker image (simple tag for debian): https://hub.docker.com/_/python/

For these instructions, substitute 'baseline' with [your-project-name].

1. Copy artifacts/postgres-Dockerfile to ../baseline-postgres/Dockerfile
1. Copy artifacts/compose.override.yaml to compose.override.yaml
1. Edit the copied compose files and replace 'baseline' with [your-project-name]
1. Build in ../baseline-postgres/: `docker build --tag baseline-postgres .`
1. Build in ../baseline/: `docker build --tag baseline .`
1. `mkdir django_root`
1. Run a container shell: `docker run --network="host" --volume ./django_root:/opt --interactive --tty baseline bash`
1. Create project using [MikeD Directory Structure](#miked-directory-structure)
1. Exit container shell
1. Configure django_root/core/settings.py, (merge artifacts/settings.py into core/settings.py,
remember to use [your-project-name] instead of 'baseline')
1. Use compose to build and run this container, and the postgres container: `docker compose up`
1. Shell into container: `docker compose exec baseline bash`

# Notes

Be aware, .gitignore, .flake8, and pyproject.toml are included in the repo, so they may need
to be edited for the new project.

## MikeD Directory Structure
Substitute 'baseline' with [new-project-name] in these instructions. In container /opt/:
```bash
django-admin startproject core .
django-admin startapp baseline
mkdir logs
```

now repo structure on host is
```text
baseline/                 (container artifacts)
  /django_root            (django project root)
  /django_root/core       (top-level package, configuration, users, etc)
  /django_root/baseline/  (this is where the magic is)
```

## Formatting and Linting

[![Code style: black](https://img.shields.io/badge/code%21style-black-000000.svg)](https://github.com/psf/black)

[Flake8](https://flake8.pycqa.org/en/latest/) linting

Do not blacken any files above ```django_root/```

## Check Code Test Coverage
```bash
docker compose exec baseline bash -c "coverage run --source='.' manage.py test"
docker compose exec baseline bash -c "coverage report"
```

## Graph Primary Models
```bash
./manage.py graph_models --output models.png core baseline
```

### Geenrate API Schema
```bash
# in baseline container
pip install pyyaml uritemplate
./manage.py generateschema --file baseline-api-openapi.yml
# can open directly in Swagger Editor
```


## Generate Documentation with Sphinx

Execute these instructions within a container shell.

Install required packages:
```bash
python3 -m pip install sphinx sphinx-autobuild sphinx_rtd_theme
```

In django_root, create docs dir and configure Sphinx (see [example conf.py](#example-sphinx-conf.py)):
```bash
mkdir docs
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

### Example Sphinx conf.py:
```py
# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys

import django


project = 'baseline'
copyright = '2025, m'
author = 'm'
release = '0.1'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.todo',
]

# project path
sys.path.insert(0, os.path.abspath('/opt/'))

#os.environ['DJANGO_SETTINGS_MODULE'] = 'core.settings'
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

templates_path = ['_templates']
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']
```
