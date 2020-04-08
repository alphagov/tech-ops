#!/usr/bin/env python3
"""
Command line interface for the testing Splunk data ingestion.
"""

import json
import os
import sys
from datetime import datetime
from time import sleep

import click

from search import poll_splunk


@click.group()
def cli():
    pass


@cli.command()
@click.option("-S", "--sleeptime", type=int, default=1)
@click.option("-t", "--timeout", type=int, default=600)
@click.option("-s", "--search", type=str)
@click.option("-u", "--username", type=str, default="")
@click.option("-p", "--password", type=str, default="")
@click.option("-h", "--hostname", type=str, default="")
@click.option("-b", "--port", type=str, default="8089")
@click.option("-o", "--outputlogs", type=bool, default=False)
@click.option("-m", "--match", type=str, default="")
@click.option("-d", "--debug", type=bool, default=False)
def poll(
    sleeptime: int,
    timeout: int,
    search: str,
    username: str,
    password: str,
    hostname: str,
    port: str,
    outputlogs: bool,
    match: str,
    debug: bool,
):
    if username != "":
        os.environ["SPLUNK_USERNAME"] = username
    if password != "":
        os.environ["SPLUNK_PASSWORD"] = password
    if hostname != "":
        os.environ["SPLUNK_HOST"] = hostname
    if port != "":
        os.environ["SPLUNK_PORT"] = port

    start_timestamp = datetime.now().timestamp()
    duration = 0.0

    if debug:
        print("Polling Splunk to find our logs...")

    while duration < timeout:
        duration = datetime.now().timestamp() - start_timestamp
        if debug:
            print(f"Current duration: {duration:.2f} seconds")
            print(f"Timeout: {timeout} seconds")

        start_of_search = datetime.now().timestamp()
        splunk_results = poll_splunk(search)
        end_of_search = datetime.now().timestamp()
        diff = end_of_search - start_of_search

        if debug:
            print(f"Took {diff:.2f} seconds to query Splunk")

        success = False
        len_splunk_results = len(splunk_results)
        if match == "":
            if len_splunk_results != 0:
                success = True
        else:
            for log in splunk_results:
                if match in str(log):
                    success = True
                    break

        if success:
            if outputlogs:
                print(json.dumps(splunk_results, indent=4, sort_keys=True))

            total_time = duration + diff
            print(f"✓ Found {len_splunk_results} log(s) in {total_time:.2f} seconds")
            sys.exit(0)

        if debug:
            print(f"No results\nSleeping for {sleeptime} seconds...")
            print("-" * 20)
        sleep(sleeptime)

    print(
        f"❌ TIMEOUT didn't find any logs after {duration:.2f} seconds", file=sys.stderr
    )
    sys.exit(1)


if __name__ == "__main__":
    cli()
