def policy(status: str) -> int:
    return int(status in ("OK", "ok", "Ok", "oK"))
