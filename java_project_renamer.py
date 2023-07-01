import os
import argparse
import shutil
import fnmatch
from pathlib import Path
import chardet

def is_text(filename):
    """
    Function to check if a file is text or binary by reading a small portion
    of the file.
    """
    try:
        with open(filename, 'r') as f:
            f.read(1024)
            return True
    except UnicodeDecodeError:
        return False

def find_and_replace(root_dir, old_namespace, new_namespace):
    # Replace . with / to match directory structure
    old_dir = old_namespace.replace('.', '/')
    new_dir = new_namespace.replace('.', '/')

    while True:
        found = False
        # Walk through root directory
        for dirpath, dirnames, filenames in os.walk(root_dir):
            if '.git' in dirpath:
                continue

            if old_dir in dirpath:
                # Compute new path name
                new_dirpath = dirpath.replace(old_dir, new_dir)
                # Rename directory
                shutil.move(dirpath, new_dirpath)
                found = True
                break  # directory structure changed, restart the search
        if not found:
            break  # if no directory was found, exit loop

    # Walk through root directory again and replace namespaces in files
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if '.git' in dirpath:
            continue

        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            if is_text(filepath):
                with open(filepath, 'r+', encoding='utf-8', errors='ignore') as f:
                    data = f.read()
                    data = data.replace(old_namespace, new_namespace)
                    f.seek(0)
                    f.write(data)
                    f.truncate()

    # Walk through root directory again and replace namespaces in directory and file names
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if '.git' in dirpath:
            continue

        for dirname in dirnames:
            if old_namespace in dirname:
                old_dirpath = os.path.join(dirpath, dirname)
                new_dirpath = old_dirpath.replace(old_namespace, new_namespace)
                shutil.move(old_dirpath, new_dirpath)
        
        for filename in filenames:
            if old_namespace in filename:
                old_filepath = os.path.join(dirpath, filename)
                new_filepath = old_filepath.replace(old_namespace, new_namespace)
                os.rename(old_filepath, new_filepath)

     # Walk through root directory again and replace namespaces in files
        for dirpath, dirnames, filenames in os.walk(root_dir):
            if '.git' in dirpath:
                continue

                for filename in filenames:
                    filepath = os.path.join(dirpath, filename)
                    if is_text(filepath):
                        with open(filepath, 'r+', encoding='utf-8', errors='ignore') as f:
                            data = f.read()
                            data = data.replace(old_namespace, new_namespace)
                            f.seek(0)
                            f.write(data)
                            f.truncate()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Find and replace a namespace in an android app')
    parser.add_argument('--root_dir', required=True, help='the directory of the root of the project')
    parser.add_argument('--old_namespace', required=True, help='the original namespace')
    parser.add_argument('--new_namespace', required=True, help='the new namespace')

    args = parser.parse_args()

    find_and_replace(args.root_dir, args.old_namespace, args.new_namespace)
    print "Rename complete, be sure to reload the files from disk in the IDE and execute build clean."
