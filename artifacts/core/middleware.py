"""
Request-scoped middleware.
"""

from core.logging import accept_request_id, reset_request_id, set_request_id


REQUEST_ID_HEADER = 'X-Request-ID'


class RequestIdMiddleware:
    """Give every request a correlation id, and echo it back to the caller.

    An inbound X-Request-ID is honoured after validation, so a trace started upstream can
    be followed through; otherwise one is minted.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = accept_request_id(request.headers.get(REQUEST_ID_HEADER))
        request.request_id = request_id
        token = set_request_id(request_id)
        try:
            response = self.get_response(request)
            response[REQUEST_ID_HEADER] = request_id
            return response
        finally:
            # threads are reused; a leaked id would mis-attribute the next request
            reset_request_id(token)
