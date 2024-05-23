from c2cwsgiutils.acceptance.connection import CacheExpected


def test_get_status(connection):
    answer = connection.get_raw(
        url="status",
        cache_expected=CacheExpected.DONT_CARE,
        cors=True,
    )
    assert answer.status_code == 200
    assert answer.text == "OK"
