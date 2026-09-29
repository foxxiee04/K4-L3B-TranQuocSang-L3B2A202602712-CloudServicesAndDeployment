import signal


class Lifecycle:
    """Quản lý trạng thái shutdown của application."""

    def __init__(self):
        self.shutting_down = False
        self._previous = {}

    def request_shutdown(self, signum=None, frame=None):
        """Đánh dấu service đang shutdown và gọi handler trước đó."""

        self.shutting_down = True

        previous = self._previous.get(signum)

        if callable(previous):
            previous(signum, frame)

    def install(self):
        """Đăng ký signal handler cho SIGTERM và SIGINT."""

        for sig in (signal.SIGTERM, signal.SIGINT):
            self._previous[sig] = signal.getsignal(sig)
            signal.signal(sig, self.request_shutdown)


lifecycle = Lifecycle()