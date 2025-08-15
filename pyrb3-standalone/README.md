# pyrb3 Standalone

This repository contains the Python components of the `rb3` project, providing tools to download financial data from the B3 Brazilian stock exchange.

## Setup

1.  Install the necessary dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Usage

This project provides two example scripts to demonstrate the library's functionality.

### List Available Indexes

To see a list of all available stock market indexes:

```bash
python3 list_indexes.py
```

### Download Index History

To download the complete historical price data for a specific index:

```bash
python3 download_index.py <INDEX_NAME>
```

For example, to download the history for the IBOVESPA index:

```bash
python3 download_index.py IBOV
```

This will create a file named `IBOV_history.csv` in the current directory containing the historical data.
