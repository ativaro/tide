import json


def main(payload: str) -> int:
    return json.loads(payload)["qty"]
