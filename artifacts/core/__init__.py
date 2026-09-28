"""
Load the Celery app whenever Django starts, so @shared_task binds to it.
"""

from core.celery import app as celery_app


__all__ = ['celery_app']
