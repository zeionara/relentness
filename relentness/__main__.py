from os import makedirs

import click

from openke.config import Config
from openke.models import TransE, ComplEx


@click.group()
def main():
    pass


def input_to_output_path(input_path: str):
    input_path_components = input_path[::-1].split("/", maxsplit=4)
    return f'{input_path_components[4][::-1]}/Models/{input_path_components[2][::-1]}/{input_path_components[1][::-1]}/TransE'


@main.command()
@click.argument('path', type=str)
@click.option('--model', '-m', type=click.Choice(['transe', 'complex']), required=True)
@click.option('--output', '-o', type=str, default=None)
@click.option('--verbose', '-v', type=bool, is_flag=True)
def test(path: str, model: str, output: str = None, verbose: bool = False):
    print(f'Got input path "{path}"')

    config = Config()

    # config.set_in_path("/home/zeio/OpenKE/benchmarks/FB15K/")
    config.set_in_path(path)
    config.set_work_threads(4)
    config.set_train_times(10)
    config.set_nbatches(10)
    config.set_alpha(0.001)
    config.set_margin(1.0)
    config.set_bern(0)
    config.set_dimension(10)
    config.set_ent_neg_rate(1)
    config.set_rel_neg_rate(0)
    config.set_opt_method("SGD")
    config.set_log_on(verbose)

    output_path = input_to_output_path(path) if output is None else output
    # print(output_path)
    makedirs(output_path, exist_ok=True)
    config.set_export_files(f"{output_path}/model.vec.tf", 0)
    config.set_out_files(f"{output_path}/embedding.vec.json")

    config.set_test_link_prediction(True)

    config.init()

    # environ['CUDA_VISIBLE_DEVICES']='7'
    config.set_model(TransE if model == 'transe' else ComplEx)

    config.run()

    config.test()


if __name__ == '__main__':
    main()
