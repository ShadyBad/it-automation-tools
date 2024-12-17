import polars as pl
import os
import json
import sys
from typing import List, Dict, Any


def load_data(file_path: str) -> List[Dict[str, Any]]:
    """
    Load JSON data from a file.

    Args:
        file_path (str): Path to the JSON file.

    Returns:
        List[Dict[str, Any]]: Parsed JSON data as a list of dictionaries.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    with open(file_path, 'r') as file:
        return pl.read_json(file)


def save_dataframe_to_csv(data: List[Dict[str, Any]], filename: str, output_dir: str = "~/Documents") -> str:
    """
    Save a list of dictionaries to a CSV file using Polars.

    Args:
        data (List[Dict[str, Any]]): Data to be saved.
        filename (str): Name of the output CSV file.
        output_dir (str): Directory to save the file.

    Returns:
        str: Full path of the saved file.
    """
    if not filename.endswith('.csv'):
        raise ValueError("Filename must have a .csv extension.")

    # Expand user directory and construct full path
    output_path = os.path.expanduser(os.path.join(output_dir, filename))

    # Create Polars DataFrame and write to CSV
    df = pl.DataFrame(data).select(pl.all().shrink_dtype())
    df.write_csv(output_path, separator=",")

    return output_path


def main():
    """
    Main function to load data from multiple JSON files, construct a DataFrame,
    and save it as a CSV.
    """
    if len(sys.argv) < 2:
        print("Usage: python script.py <file1.json> <file2.json> ... <file.json>")
        sys.exit(1)

    try:
        combined = []

        # Process each file provided as command-line arguments
        for file_path in sys.argv[1:]:
            print(f"Loading data from: {file_path}")
            data = load_data(file_path)
            if not isinstance(data, list):
                raise ValueError(f"File {file_path} does not contain a list of dictionaries.")
            combined.extend(data)

        # Get filename from user
        filename = input("Enter the filename (e.g. 'data.csv'): ").strip()
        if not filename:
            raise ValueError("Filename cannot be empty.")

        # Save combined data to CSV
        save_path = save_dataframe_to_csv(combined, filename)
        print(f"DataFrame successfully saved to: {save_path}")

    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
