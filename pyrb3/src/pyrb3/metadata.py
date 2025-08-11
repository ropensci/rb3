import hashlib
import json
from dataclasses import dataclass, field
from typing import Dict, Any, Optional

@dataclass
class Metadata:
    """
    Represents the metadata for a single data file download.
    """
    template_name: str
    download_args: Dict[str, Any]
    download_checksum: str = field(init=False)
    downloaded_path: Optional[str] = None
    is_downloaded: bool = False
    is_processed: bool = False
    is_valid: bool = False

    def __post_init__(self):
        """
        Initializes the download_checksum after the object is created.
        """
        self.download_checksum = self._create_checksum()

    def _create_checksum(self) -> str:
        """
        Creates a stable SHA256 checksum from the template name and download args.
        """
        # Sort the args by key to ensure the JSON string is stable
        sorted_args = json.dumps(self.download_args, sort_keys=True)

        hasher = hashlib.sha256()
        hasher.update(self.template_name.encode())
        hasher.update(sorted_args.encode())

        return hasher.hexdigest()
