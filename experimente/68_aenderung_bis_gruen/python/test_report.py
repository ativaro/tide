"""Run the same six report examples and the imported package example."""
from io import BytesIO

import measurements
from report import report


def check_case(content, budget, expected, error=False):
    try:
        actual = report(BytesIO(content), budget, 80 if budget >= 0 else 0)
    except measurements.ReportError as failure:
        assert error, failure.fields
        actual = failure.fields
    else:
        assert not error
    assert actual == expected, (actual, expected)


check_case(b"80\r\n81\n98", 9, {"above": 2, "peak": {"some": 98}})
check_case(b"", 0, {"above": 0, "peak": {"none": True}})
check_case(b"80\r\n81\n98", 8, {"code": "E_LIMIT", "input_line": 3}, error=True)
check_case(b"80\nx\n", 5, {"code": "E_DATA", "reason": "invalid_integer", "input_line": 2}, error=True)
check_case(b"12\r", 3, {"code": "E_DATA", "reason": "invalid_integer", "input_line": 1}, error=True)
check_case(b"", -1, {"code": "E_LIMIT", "input_line": 1}, error=True)
assert measurements.parse(b"-027", 1) == -27
print('{"passed":7}')
