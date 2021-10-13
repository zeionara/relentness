from os import makedirs, environ

import click
from openke.config import Config
from openke.models import TransE


@click.group()
def main():
    pass


def input_to_output_path(input_path: str):
    input_path_components = input_path[::-1].split("/", maxsplit=4)
    return f'{input_path_components[4][::-1]}/Models/{input_path_components[2][::-1]}/{input_path_components[1][::-1]}/TransE'


@main.command()
@click.argument('path', type=str)
@click.option('--output', '-o', type = str, default = None)
def test_transe(path: str, output: str = None):
    print(f'Got input path "{path}"')

    config = Config()

    config.set_in_path(path)
    config.set_work_threads(4)
    config.set_train_times(10)
    config.set_nbatches(100)
    config.set_alpha(0.001)
    config.set_margin(1.0)
    config.set_bern(0)
    config.set_dimension(50)
    config.set_ent_neg_rate(1)
    config.set_rel_neg_rate(0)
    config.set_opt_method("SGD")

    output_path = input_to_output_path(path) if output is None else output
    # print(output_path)
    makedirs(output_path, exist_ok=True)
    config.set_export_files(f"{output_path}/model.vec.tf", 0)
    config.set_out_files(f"{output_path}/embedding.vec.json")

    config.set_test_link_prediction(True)

    config.init()

    # environ['CUDA_VISIBLE_DEVICES']='7'
    config.set_model(TransE)

    config.run()

    config.predict_head_entity(1, 0, 0)
    config.test()


if __name__ == '__main__':
    main()
