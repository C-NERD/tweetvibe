from dataclasses import dataclass

@dataclass
class ErrorCode:

    status : bool
    msg : str

@dataclass
class ErrorData:

    status : bool
    msg : str
    data : any

    def toErrorCode(self) -> ErrorCode :

        return ErrorCode(self.status, self.msg)

