import requests
from pathlib import Path
from typing import Any, Dict, Optional
from datetime import date
import json
import base64
from urllib.parse import urlparse, urlunparse
from pyrb3.template import Template

def _handle_response(response: requests.Response, dest_path: Path) -> bool:
    """Handles the response from a requests call."""
    try:
        response.raise_for_status()
        dest_path.write_bytes(response.content)
        return True
    except requests.exceptions.RequestException as e:
        print(f"Failed to download from {response.url}: {e}")
        return False

def _get_file(url: str, dest_path: Path, params: Optional[Dict[str, Any]] = None) -> bool:
    """Downloads a file using GET, with optional query parameters."""
    try:
        response = requests.get(url, params=params, timeout=30)
        return _handle_response(response, dest_path)
    except requests.exceptions.RequestException as e:
        print(f"Request failed for {url}: {e}")
        return False

def _post_file(url: str, dest_path: Path, data: Dict[str, Any]) -> bool:
    """Downloads a file using POST with form data."""
    try:
        response = requests.post(url, data=data, timeout=30)
        return _handle_response(response, dest_path)
    except requests.exceptions.RequestException as e:
        print(f"Request failed for {url}: {e}")
        return False

def _b3_url_encode(url: str, **kwargs: Any) -> str:
    """
    Replicates the B3's specific URL encoding scheme.
    Converts args to JSON, then base64, then appends to the URL path.
    """
    # Use sort_keys=True for a stable, predictable order.
    params_json = json.dumps(kwargs, sort_keys=True, separators=(",", ":"))
    params_b64 = base64.b64encode(params_json.encode()).decode()

    parsed_url = urlparse(url)
    # Ensure the path ends with a slash before appending the new segment
    new_path = parsed_url.path.rstrip('/') + '/' + params_b64

    return urlunparse(parsed_url._replace(path=new_path))

def simple_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = template.downloader["url"]
    return _get_file(url, dest_path)

def sprintf_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url_template = template.downloader["url"]
    arg_names = list(template.downloader.get("args", {}).keys())
    ordered_args = tuple(kwargs[name] for name in arg_names)
    formatted_url = url_template % ordered_args
    return _get_file(formatted_url, dest_path)

def datetime_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url_template = template.downloader["url"]
    refdate: date = kwargs["refdate"]
    formatted_url = refdate.strftime(url_template)
    return _get_file(formatted_url, dest_path)

def settlement_prices_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = template.downloader["url"]
    refdate: date = kwargs["refdate"]
    post_data = {"dData1": refdate.strftime("%d/%m/%Y")}
    return _post_file(url, dest_path, data=post_data)

def curve_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = template.downloader["url"]
    refdate: date = kwargs["refdate"]
    curve_name: str = kwargs["curve_name"]
    params = {
        "Data": refdate.strftime("%d/%m/%Y"),
        "Data1": refdate.strftime("%Y%m%d"),
        "slcTaxa": curve_name,
    }
    return _get_file(url, dest_path, params=params)

def stock_indexes_composition_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = _b3_url_encode(
        template.downloader["url"],
        pageNumber=1,
        pageSize=9999
    )
    return _get_file(url, dest_path)

def stock_indexes_theo_portfolio_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = _b3_url_encode(
        template.downloader["url"],
        pageNumber=1,
        pageSize=9999,
        language="en-us",
        index=kwargs["index"]
    )
    return _get_file(url, dest_path)

def stock_indexes_current_portfolio_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = _b3_url_encode(
        template.downloader["url"],
        pageNumber=1,
        pageSize=9999,
        language="en-us",
        index=kwargs["index"],
        segment=2
    )
    return _get_file(url, dest_path)

def stock_indexes_statistics_download(template: Template, dest_path: Path, **kwargs: Any) -> bool:
    url = _b3_url_encode(
        template.downloader["url"],
        language="en-us",
        index=kwargs["index"],
        year=kwargs["year"]
    )
    return _get_file(url, dest_path)
