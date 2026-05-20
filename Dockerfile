FROM python:3.15.0a6-trixie

WORKDIR /opt/app

# override at runtime when developing by using '--env' for docker run,
# or 'environment' in compose
ENV IS_DEV=false

# postgres-python with django
ARG PPG_DEPS="python3-dev libpq-dev"
# packages for postgres-python with django, GraphViz model visualization (prerequisite of
# pygraphviz installed by pip from requirements-dev.outline)
ARG GRAPH_DEPS="graphviz graphviz-dev"
ARG CONTAINER_UID
ARG CONTAINER_GID

RUN set -eux; \
    apt update; \
    apt upgrade --yes; \
    apt install --yes --no-install-recommends \
        $PPG_DEPS \
        $GRAPH_DEPS; \
    rm -rf /var/lib/apt/lists/*

# python dependencies
COPY artifacts/requirements.outline ./requirements.txt
RUN set -eux; \
    python -m pip install --requirement requirements.txt;

# assuming ipython is installed in requirements.txt,
# find the installed ultratb.py and patch it for readable error highlighting
RUN ULTRATB_PATH="$(python3 -c 'import IPython.core.ultratb,inspect,os; print(os.path.abspath(inspect.getfile(IPython.core.ultratb)))')" \
    && sed --in-place 's/tb_highlight *= *"bg:ansiyellow"/tb_highlight = "bg:ansired"/' "$ULTRATB_PATH"

# create devuser account with UID/GID matching CONTAINER_UID/CONTAINER_GID
RUN set -eux; \
    groupadd --gid ${CONTAINER_GID} devuser; \
    useradd --uid ${CONTAINER_UID} --gid ${CONTAINER_GID} \
            --home /home/devuser --no-create-home --shell /bin/bash devuser

# create home directory for devuser
RUN mkdir --parents /home/devuser

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

# Fix devuser home ownership; 700 so only devuser can access it
RUN chown --recursive devuser:devuser /home/devuser && chmod 700 /home/devuser

# django
ENV DJANGO_SETTINGS_MODULE=core.settings

EXPOSE 8000

COPY artifacts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY django_root/ /opt/app/
RUN mkdir --parents /opt/app/logs && \
    chown --recursive devuser:devuser /opt/app
