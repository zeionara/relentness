import os
from uuid import uuid4


def ensure_parent_folders_exist(filename: str):
    folder_path = os.path.split(filename)[0]
    if len(folder_path) > 0:
        os.makedirs(folder_path, exist_ok=True)


def input_to_output_path(input_path: str, model: str, middle_component: str, seed: int = None):
    input_path_components = input_path[::-1].split("/", maxsplit=4)
    return f'{input_path_components[4][::-1]}/{middle_component}/{input_path_components[2][::-1]}/{input_path_components[1][::-1]}/{model}/{uuid4() if seed is None else seed}'


# For example, Assets/Corpora/Demo/0000/ -> Assets/Models/Demo/0000/transe/17
def input_to_output_model_path(input_path: str, model: str, seed: int = None):
    return input_to_output_path(input_path, model, 'Models', seed)


def input_to_output_image_path(input_path: str, model: str, seed: int = None):
    return input_to_output_path(input_path, model, 'Images', seed)
