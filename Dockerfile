FROM python:3.14.0rc3-trixie

WORKDIR /opt

# override at runtime when developing by using '--env' for docker run,
# or 'environment' in compose
ENV IS_DEV=false

RUN set -eux; \
    apt update; \
    apt upgrade --yes; \
    apt install --yes --no-install-recommends vim vim-syntastic exuberant-ctags;

# postgres for python with django
RUN set -eux; \
    apt install --yes --no-install-recommends python3-dev libpq-dev;

# for django-extensions GraphViz model visualization, this is a prerequisite of
# pygraphviz installed by pip from requirements.txt
RUN set -eux; \
    apt install --yes --no-install-recommends graphviz graphviz-dev;

# python dependencies
COPY artifacts/requirements.outline ./requirements.txt
RUN set -eux; \
    python -m pip install --requirement requirements.txt;

# environment
COPY container-rc/bashrc /root/.bashrc
COPY container-rc/inputrc /root/.inputrc
COPY container-rc/vimrc /root/.vimrc
# IPython config
RUN set -eux; \
    mkdir --parents /root/.ipython/profile_default;
COPY container-rc/ipython_config.py /root/.ipython/profile_default/ipython_config.py

# django
ENV DJANGO_SETTINGS_MODULE=core.settings
