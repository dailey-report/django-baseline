"""
Request correlation and log formatting.

Every record carries a request_id, held in a ContextVar so it follows the work rather than
being threaded through every call.
"""

import json
import logging
import re
import uuid
from contextvars import ContextVar


# '-' rather than '', so a line with no request in scope is visibly unattributed
NO_REQUEST = '-'

_request_id = ContextVar('request_id', default=NO_REQUEST)

# inbound ids are caller-controlled and land in log output; refuse any that forge a line
_SAFE_REQUEST_ID = re.compile(r'^[A-Za-z0-9._@:+-]{1,128}$')

# attributes every LogRecord defines; anything else was added by the caller via extra=
_STANDARD_ATTRS = frozenset(logging.LogRecord('', 0, '', 0, '', (), None).__dict__) | {
    'asctime',
    'message',
    'taskName',
}


def get_request_id():
    """Return the correlation id for the work in progress."""
    return _request_id.get()


def set_request_id(value):
    """Bind value as the current correlation id; returns a reset token."""
    return _request_id.set(value)


def reset_request_id(token):
    """Restore whatever correlation id was in scope before token was taken."""
    _request_id.reset(token)


def new_request_id():
    """Mint a fresh correlation id."""
    return uuid.uuid4().hex


def accept_request_id(value):
    """Return value if it is safe to log verbatim, else a fresh id."""
    if value and _SAFE_REQUEST_ID.match(value):
        return value
    return new_request_id()


class RequestIdFilter(logging.Filter):
    """Attach the current correlation id to every record."""

    def filter(self, record):
        record.request_id = get_request_id()
        return True


class JsonFormatter(logging.Formatter):
    """Emit one JSON object per record; extra= fields become top-level keys."""

    def format(self, record):
        payload = {
            'time': self.formatTime(record, '%Y-%m-%dT%H:%M:%S'),
            'level': record.levelname,
            'logger': record.name,
            'line': f'{record.pathname}:{record.lineno}',
            'request_id': getattr(record, 'request_id', NO_REQUEST),
            'message': record.getMessage(),
        }
        if record.exc_info:
            payload['exception'] = self.formatException(record.exc_info)
        for key, value in record.__dict__.items():
            if key not in _STANDARD_ATTRS and key not in payload:
                payload[key] = value
        return json.dumps(payload, default=str)
