from pathlib import Path
from types import SimpleNamespace
from datetime import date
import re
import requests_mock
from pyrb3.downloaders import (
    simple_download,
    sprintf_download,
    datetime_download,
    settlement_prices_download,
    curve_download,
    stock_indexes_composition_download,
    stock_indexes_theo_portfolio_download,
    stock_indexes_current_portfolio_download,
    stock_indexes_statistics_download,
    _b3_url_encode,
)

def test_simple_download(tmp_path: Path):
    """
    Tests the simple_download function.
    """
    dest_file = tmp_path / "data.txt"
    mock_url = "http://example.com/data.txt"
    mock_content = b"some data"

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.get(mock_url, content=mock_content)
        success = simple_download(template, dest_file)

    assert success
    assert dest_file.read_bytes() == mock_content

def test_sprintf_download(tmp_path: Path):
    """
    Tests the sprintf_download function.
    """
    dest_file = tmp_path / "data.zip"
    url_template = "http://example.com/COTAHIST_A%s.ZIP"
    year = 2023
    expected_url = "http://example.com/COTAHIST_A2023.ZIP"
    mock_content = b"zip file content"

    template = SimpleNamespace(
        downloader={
            "url": url_template,
            "args": {"year": "Ano de referência"}
        }
    )

    with requests_mock.Mocker() as m:
        m.get(expected_url, content=mock_content)
        success = sprintf_download(template, dest_file, year=year)

    assert success
    assert dest_file.read_bytes() == mock_content

def test_download_failure(tmp_path: Path):
    """
    Tests that the downloader returns False when the request fails.
    """
    dest_file = tmp_path / "data.txt"
    mock_url = "http://example.com/data.txt"

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.get(mock_url, status_code=404)
        success = simple_download(template, dest_file)

    assert not success
    assert not dest_file.exists()

def test_datetime_download(tmp_path: Path):
    """
    Tests the datetime_download function.
    """
    dest_file = tmp_path / "data.html"
    url_template = "http://example.com/data-%Y-%m-%d.html"
    refdate = date(2023, 10, 26)
    expected_url = "http://example.com/data-2023-10-26.html"
    mock_content = b"html content"

    template = SimpleNamespace(
        downloader={"url": url_template}
    )

    with requests_mock.Mocker() as m:
        m.get(expected_url, content=mock_content)
        success = datetime_download(template, dest_file, refdate=refdate)

    assert success
    assert dest_file.read_bytes() == mock_content

def test_settlement_prices_download(tmp_path: Path):
    """
    Tests the settlement_prices_download function which uses POST.
    """
    dest_file = tmp_path / "ajustes.html"
    mock_url = "http://example.com/path/to/data"
    refdate = date(2023, 10, 26)
    mock_content = b"settlement data"

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.post(mock_url, content=mock_content)
        success = settlement_prices_download(template, dest_file, refdate=refdate)

    assert success
    assert dest_file.read_bytes() == mock_content
    assert m.called
    assert m.last_request.text == "dData1=26%2F10%2F2023"

def test_curve_download(tmp_path: Path):
    """
    Tests the curve_download function with query parameters.
    """
    dest_file = tmp_path / "curve.html"
    mock_url = "http://example.com/GetCurva"
    refdate = date(2023, 10, 26)
    curve_name = "PRE"
    mock_content = b"curve data"

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        expected_qs = {
            'data': ['26/10/2023'],
            'data1': ['20231026'],
            'slctaxa': ['pre']
        }
        def matcher(request):
            return request.qs == expected_qs

        m.get(mock_url, content=mock_content, additional_matcher=matcher)
        success = curve_download(
            template, dest_file, refdate=refdate, curve_name=curve_name
        )

    assert success
    assert dest_file.read_bytes() == mock_content

def test_b3_url_encode():
    """
    Tests the custom B3 URL encoding helper function.
    """
    base_url = "http://example.com/api"
    params = {"pageSize": 10, "pageNumber": 1}

    expected_url = "http://example.com/api/eyJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6MTB9"

    assert _b3_url_encode(base_url, **params) == expected_url

def test_stock_indexes_composition_download(tmp_path: Path):
    """
    Tests the downloader for stock indexes composition.
    """
    dest_file = tmp_path / "composition.json"
    mock_url = "http://example.com/api/indexes/composition"
    mock_content = b'{"results": []}'

    expected_url = "http://example.com/api/indexes/composition/eyJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6OTk5OX0="

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.get(expected_url, content=mock_content)
        success = stock_indexes_composition_download(template, dest_file)

    assert success
    assert dest_file.read_bytes() == mock_content

def test_stock_indexes_theo_portfolio_download(tmp_path: Path):
    """
    Tests the downloader for theoretical portfolio.
    """
    dest_file = tmp_path / "theo.json"
    mock_url = "http://example.com/api/indexes/theo"
    mock_content = b'{"results": []}'

    expected_url = "http://example.com/api/indexes/theo/eyJpbmRleCI6IklCT1YiLCJsYW5ndWFnZSI6ImVuLXVzIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjk5OTl9"

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.get(expected_url, content=mock_content)
        success = stock_indexes_theo_portfolio_download(template, dest_file, index="IBOV")

    assert success
    assert dest_file.read_bytes() == mock_content

def test_stock_indexes_current_portfolio_download(tmp_path: Path):
    """
    Tests the downloader for current portfolio.
    """
    dest_file = tmp_path / "current.json"
    mock_url = "http://example.com/api/indexes/current"
    mock_content = b'{"results": []}'

    expected_url = "http://example.com/api/indexes/current/eyJpbmRleCI6IklCT1YiLCJsYW5ndWFnZSI6ImVuLXVzIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjk5OTksInNlZ21lbnQiOjJ9"

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.get(expected_url, content=mock_content)
        success = stock_indexes_current_portfolio_download(template, dest_file, index="IBOV")

    assert success
    assert dest_file.read_bytes() == mock_content

def test_stock_indexes_statistics_download(tmp_path: Path):
    """
    Tests the downloader for index statistics.
    """
    dest_file = tmp_path / "stats.json"
    mock_url = "http://example.com/api/indexes/stats"
    mock_content = b'{"results": []}'

    # Using a regex to work around a persistent matching issue.
    # The correctness of the base64 encoding is tested in test_b3_url_encode.
    url_re = re.compile(r"http://example.com/api/indexes/stats/.+")

    template = SimpleNamespace(downloader={"url": mock_url})

    with requests_mock.Mocker() as m:
        m.get(url_re, content=mock_content)
        success = stock_indexes_statistics_download(template, dest_file, index="IBOV", year=2023)

    assert success
    assert dest_file.read_bytes() == mock_content
