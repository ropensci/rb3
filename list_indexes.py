import sys
import json
from pathlib import Path
import tempfile

# Add the pyrb3 source directory to the Python path
sys.path.insert(0, str(Path(__file__).resolve().parent / "pyrb3" / "src"))

from pyrb3.template import Template
from pyrb3.downloaders import stock_indexes_composition_download

def main():
    """
    Retrieves and prints the list of available B3 indexes.
    """
    template = Template("b3-indexes-composition")

    with tempfile.NamedTemporaryFile(delete=False) as temp_file:
        temp_path = Path(temp_file.name)

    if stock_indexes_composition_download(template, temp_path):
        with open(temp_path, "r", encoding="latin1") as f:
            data = json.load(f)

        all_indexes = set()
        for item in data.get("results", []):
            indexes = item.get("indexes", "").split(",")
            for index in indexes:
                if index:
                    all_indexes.add(index.strip())

        if all_indexes:
            print("Available indexes:")
            for index in sorted(list(all_indexes)):
                print(f"- {index}")
        else:
            print("No indexes found.")

        temp_path.unlink() # Clean up the temporary file
    else:
        print("Failed to download index composition data.")

if __name__ == "__main__":
    main()
