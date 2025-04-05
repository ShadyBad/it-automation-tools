# IT Automation Tools

This repository offers a suite of Python and Powershell-based tools designed to streamline various IT tasks, enhancing efficiency and productivity.

## Tools Included

- **JSON to CSV**: Combines one or more JSON files into a single CSV using the `Polars` library.

### JSON to CSV Script

The `json_to_csv.py` script provides functionality to:

1. Load JSON data from multiple files.
2. Validate that the files contain a list of dictionaries.
3. Combine the data into a single dataset shrinking the dtypes for efficiency.
4. Save the dataset as a CSV file with a user-specified name in the directory of choice.

#### How to Use

1. Run the script from the command line:
   ```bash
   python json_to_csv.py <file1.json> <file2.json> ... <fileN.json>
   ```
2. Follow the on-screen prompts to name the output CSV file.

### Example

Suppose you have two JSON files, `data1.json` and `data2.json`. You can convert them into a single CSV file as follows:
```bash
python json_to_csv.py data1.json data2.json
```
When prompted, enter the desired filename (e.g., `combined_data.csv`).

### Error Handling

- If a specified file doesn't exist, the script raises a `FileNotFoundError`.
- Only JSON files containing a list of dictionaries are accepted. Otherwise, a `ValueError` is raised.

## Prerequisites

Ensure Python 3.x is installed. Required Python packages include:

- `Polars`

Install dependencies using pip:

```bash
pip install polars
```

## Contributions

Contributions are welcome. Please fork the repository, create a new branch for your feature or bug fix, and submit a pull request.
