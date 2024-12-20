# standard libraries
import sys


def compare_txt_files(file1_path, file2_path):
    """
    Compares two TXT files with two columns (file name and class number) separated by commas,
    ignoring the order of rows. Issues errors when they do not match.
    Assumes no header row in the files.

    Args:
      file1_path: Path to the first TXT file.
      file2_path: Path to the second TXT file.

    Returns:
      True if the files have the same data (ignoring order), False otherwise.
    """

    data1 = {}
    data2 = {}

    with open(file1_path, "r") as file1:
        for line in file1:
            filename, class_num = line.strip().split(",")  # Split using comma
            data1[filename] = int(class_num)

    with open(file2_path, "r") as file2:
        for line in file2:
            filename, class_num = line.strip().split(",")  # Split using comma
            data2[filename] = int(class_num)

    if data1 != data2:
        # Find missing entries
        missing_in_file2 = set(data1.keys()) - set(data2.keys())
        missing_in_file1 = set(data2.keys()) - set(data1.keys())

        if missing_in_file2:
            print(f"Error: The following entries are missing in {file2_path}:")
            for filename in missing_in_file2:
                print(f"  - {filename} (class: {data1[filename]})")

        if missing_in_file1:
            print(f"Error: The following entries are missing in {file1_path}:")
            for filename in missing_in_file1:
                print(f"  - {filename} (class: {data2[filename]})")

        # Find mismatched class numbers
        for filename in set(data1.keys()) & set(data2.keys()):
            if data1[filename] != data2[filename]:
                print(f"Error: Mismatched class number for {filename}:")
                print(f"  - {file1_path}: {data1[filename]}")
                print(f"  - {file2_path}: {data2[filename]}")

        return False

    return True


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python compare_txt.py <file1.txt> <file2.txt>")
        sys.exit(1)

    file1 = sys.argv[1]
    file2 = sys.argv[2]

    if compare_txt_files(file1, file2):
        print("\033[92mThe model predictions are correct.\033[0m")
    else:
        print("\033[91mThe model predictions are not correct.\033[0m")
