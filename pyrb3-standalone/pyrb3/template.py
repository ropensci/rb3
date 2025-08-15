import yaml
import pathlib
from typing import Any, Dict, List

class Template:
    """
    A class to represent a data template.

    Loads, parses, and validates a YAML template file from the 'templates' directory.
    """

    def __init__(self, template_name: str):
        """
        Initializes the Template object.

        Args:
            template_name: The name of the template (without the .yaml extension).
        """
        self.name = template_name
        self._data = self._load_template()

    def _load_template(self) -> Dict[str, Any]:
        """
        Loads and parses the YAML template file.
        """
        # Note: Using a simple file path for now.
        # This will be replaced with importlib.resources to handle installed packages.
        template_path = pathlib.Path(__file__).parent / "templates" / f"{self.name}.yaml"
        if not template_path.exists():
            raise FileNotFoundError(f"Template '{self.name}' not found at {template_path}")

        with open(template_path, "r") as f:
            return yaml.safe_load(f)

    @property
    def id(self) -> str:
        return self._data["id"]

    @property
    def downloader(self) -> Dict[str, Any]:
        return self._data["downloader"]

    @property
    def reader(self) -> Dict[str, Any]:
        return self._data["reader"]

    @property
    def writers(self) -> Dict[str, Any]:
        return self._data["writers"]

    @property
    def fields(self) -> List[Dict[str, Any]]:
        return self._data["fields"]
