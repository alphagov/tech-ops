import os
from functools import lru_cache
from time import sleep
from typing import Any, List

from splunklib import client  # type: ignore
from splunklib.results import ResultsReader  # type: ignore


@lru_cache()  # type: ignore
def splunk_service():
    """Create a client to connect to Splunk."""
    u = os.environ["SPLUNK_USERNAME"]
    p = os.environ["SPLUNK_PASSWORD"]
    h = os.environ["SPLUNK_HOST"]
    s = os.environ["SPLUNK_PORT"]

    service = client.connect(host=h, port=s, username=u, password=p)

    return service


def query_splunk(service, query: str, kwargs: dict) -> List[dict]:
    """Make a splunk search on `service`."""
    job = service.jobs.create(query, **kwargs)
    query_results: List[dict] = []
    while not job.is_done():
        sleep(0.1)
    query_results = [r for r in ResultsReader(job.results())]
    job.cancel()

    return query_results


def poll_splunk(query: str, earliest="-1h", latest="now") -> List[Any]:
    """Query Splunk"""
    service = splunk_service()
    search_kwargs = {
        "exec_mode": "normal",
        "earliest_time": earliest,
        "latest_time": latest,
    }
    return query_splunk(service, query, search_kwargs)
