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

# assuming ipython is installed in requirements.txt,
# find the installed ultratb.py and patch it for readable error highlighting
RUN ULTRATB_PATH="$(python3 -c 'import IPython.core.ultratb,inspect,os; print(os.path.abspath(inspect.getfile(IPython.core.ultratb)))')" \
    && sed -i 's/tb_highlight *= *"bg:ansiyellow"/tb_highlight = "bg:ansired"/' "$ULTRATB_PATH"

# create home directory for non-root users
RUN mkdir -p /home/devuser

# environment
COPY container-rc/bashrc /root/.bashrc
COPY container-rc/inputrc /root/.inputrc
COPY container-rc/vimrc /root/.vimrc
COPY container-rc/bashrc /home/devuser/.bashrc
COPY container-rc/inputrc /home/devuser/.inputrc
COPY container-rc/vimrc /home/devuser/.vimrc

# IPython config for both
RUN set -eux; \
    mkdir --parents /root/.ipython/profile_default; \
    mkdir --parents /home/devuser/.ipython/profile_default;

COPY container-rc/ipython_config.py /root/.ipython/profile_default/ipython_config.py
COPY container-rc/ipython_config.py /home/devuser/.ipython/profile_default/ipython_config.py

# Make devuser home accessible to any UID
RUN chmod -R 755 /home/devuser

# django
ENV DJANGO_SETTINGS_MODULE=core.settings
