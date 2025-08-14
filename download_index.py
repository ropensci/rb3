import sys
import json
import argparse
import tempfile
import csv
from pathlib import Path
from datetime import date

# Add the pyrb3 source directory to the Python path
sys.path.insert(0, str(Path(__file__).resolve().parent / "pyrb3" / "src"))

from pyrb3.template import Template
from pyrb3.downloaders import stock_indexes_statistics_download

def process_data(data, index_name, year):
    """Processes the raw index data into a time series format."""
    processed_rows = []
    if not data.get("results"):
        return processed_rows

    for item in data.get("results", []):
        if item.get("day") is None:
            continue
        day = int(item.get("day"))
        for i in range(1, 13):
            month_key = f"rateValue{i}"
            if month_key in item and item[month_key] is not None:
                try:
                    value_str = item[month_key].replace(",", "")
                    value = float(value_str)
                    ref_date = date(year, i, day)
                    processed_rows.append([ref_date.isoformat(), index_name, value])
                except (ValueError, TypeError):
                    continue
    return processed_rows

def main():
    """
    Downloads the entire historical data for a given B3 index and saves it to a CSV file.
    """
    parser = argparse.ArgumentParser(description="Download B3 index historical data.")
    parser.add_argument("index", help="The name of the index (e.g., IBOV, SMLL).")
    args = parser.parse_args()

    template = Template("b3-indexes-historical-data")
    all_rows = []

    # Let's assume the current year is 2024 for stable testing
    current_year = 2024
    consecutive_empty_years = 0

    print(f"Starting download for the entire history of index '{args.index}'...")

    for year in range(current_year, 1999, -1):
        with tempfile.NamedTemporaryFile(delete=False, mode='w+', suffix=".json") as temp_file:
            temp_path = Path(temp_file.name)

        print(f"Downloading data for {year}...")
        success = stock_indexes_statistics_download(
            template, temp_path, index=args.index, year=str(year)
        )

        if success:
            with open(temp_path, "r", encoding="utf8") as f:
                raw_data = json.load(f)

            processed_rows = process_data(raw_data, args.index, year)

            if processed_rows:
                all_rows.extend(processed_rows)
                consecutive_empty_years = 0
            else:
                consecutive_empty_years += 1

            temp_path.unlink()
        else:
            consecutive_empty_years += 1
            temp_path.unlink()

        # Stop if we don't find data for 3 consecutive years
        if consecutive_empty_years >= 3:
            print(f"No data found for {consecutive_empty_years} consecutive years. Stopping.")
            break

    if all_rows:
        # Sort data by date
        all_rows.sort(key=lambda x: x[0])

        output_filename = f"{args.index}_history.csv"
        with open(output_filename, "w", newline="", encoding="utf8") as csv_file:
            writer = csv.writer(csv_file)
            writer.writerow(["refdate", "index", "value"])
            writer.writerows(all_rows)
        print(f"Historical data successfully saved to '{output_filename}'")
    else:
        print(f"No historical data found for index '{args.index}'.")


if __name__ == "__main__":
    main()
