from typing import Optional
from dataclasses import dataclass


@dataclass
class GpgAuthContext:
    passphrase: Optional[str] = None


OptGpgAuthContext = Optional[GpgAuthContext]
