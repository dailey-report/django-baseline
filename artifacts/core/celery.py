"""
Celery application.

Worker log lines carry the correlation id of whatever queued the task (see core.logging),
when the caller passes it as the request_id keyword argument.
"""

import os

from celery import Celery
from celery.signals import task_postrun, task_prerun

from core.logging import NO_REQUEST, reset_request_id, set_request_id


os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

app = Celery('core')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# keyed by task id, so concurrent tasks in one worker cannot restore each other's id
_tokens = {}


@task_prerun.connect
def _bind_request_id(task_id=None, task=None, kwargs=None, **_extra):
    """Adopt the correlation id the caller queued this task with."""
    request_id = (kwargs or {}).get('request_id') or NO_REQUEST
    _tokens[task_id] = set_request_id(request_id)


@task_postrun.connect
def _unbind_request_id(task_id=None, **_extra):
    """Release the correlation id so a reused worker does not misattribute work."""
    token = _tokens.pop(task_id, None)
    if token is not None:
        reset_request_id(token)
