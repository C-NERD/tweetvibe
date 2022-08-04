from dataclasses import dataclass

@dataclass
class ErrorData:

    status : bool
    msg : str
    data : any

    def __iter__(self) -> dict :

        yield "status", self.status,
        yield "msg", self.msg,
        yield "data", self.data

