import os

import pytest  # type: ignore

from search import splunk_service


def test_splunk_service():
    os.environ["SPLUNK_USERNAME"] = "test"
    os.environ["SPLUNK_PASSWORD"] = "non-exist"
    os.environ["SPLUNK_HOST"] = "127.0.0.1"
    os.environ["SPLUNK_PORT"] = "1290"

    with pytest.raises(Exception) as execinfo:
        splunk_service()

    assert execinfo.value.args[0] == 111
    assert str(execinfo.value) == "[Errno 111] Connection refused"
