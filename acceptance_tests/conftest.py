"""
Common fixtures for every tests.
"""

import os

import pytest
from c2cwsgiutils.acceptance import utils
from c2cwsgiutils.acceptance.connection import Connection

BASE_URL = os.environ.get("BASE_URL", "http://localhost:8080/")


@pytest.fixture
def connection():
    """
    Fixture that returns a connection to a running batch container.
    """
    utils.wait_url(BASE_URL + "/status", timeout=30)
    return Connection(BASE_URL, "http://localhost:8080")
