"""
Test runner.
"""

import logging

from django.test.runner import DiscoverRunner
from django.test.utils import override_settings


class QuietTestRunner(DiscoverRunner):
    """Silence application logging and run Celery tasks inline for the test run.

    logging.disable suppresses assertLogs too, so a test asserting on log output must
    re-enable logging for its own duration.
    """

    def run_tests(self, *args, **kwargs):
        logging.disable(logging.CRITICAL)
        # eager propagates exceptions, so a failing task fails its test
        eager = override_settings(
            CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True
        )
        eager.enable()
        try:
            return super().run_tests(*args, **kwargs)
        finally:
            eager.disable()
            logging.disable(logging.NOTSET)
