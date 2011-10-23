from erlport import Port, Protocol, String, Atom, String
import time

# Inherit custom protocol from erlport.Protocol
class TaskProtocol(Protocol):
    def handle_msg(self, content):
        time.sleep(2),
        return Atom("ok"),String(content)


if __name__ == "__main__":
    proto = TaskProtocol()
    proto.run(Port(use_stdio=True))
