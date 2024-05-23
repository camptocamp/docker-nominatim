from c2cwsgiutils.acceptance.connection import CacheExpected


def test_search(connection):
    answer = connection.get_raw(
        url="search?q=12,simsgasse",
        cache_expected=CacheExpected.DONT_CARE,
        cors=True,
    )
    assert "application/json" in answer.headers["content-type"]
    assert answer.status_code == 200
    assert answer.json()[0].get("display_name") == "Simsgasse, Eschen, Unterland, 9492, Liechtenstein"
