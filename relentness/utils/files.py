import os


def ensure_parent_folders_exist(filename: str):
    folder_path = os.path.split(filename)[0]
    if len(folder_path) > 0:
        os.makedirs(folder_path, exist_ok=True)
