from erlport import Port, Protocol, String, Atom, String
import time

# Inherit custom protocol from erlport.Protocol
class TaskProtocol(Protocol):
    def handle_msg(self, content):
        time.sleep(1)
        return Atom("ok")


if __name__ == "__main__":
    proto = TaskProtocol()
    proto.run(Port(packet=4, use_stdio=True))
