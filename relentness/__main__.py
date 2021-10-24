from os import makedirs

import click
from uuid import uuid4
import tensorflow as tf
from keras.models import Model
from shutil import rmtree

from openke.config import Config
from openke.models import TransE, ComplEx


@click.group()
def main():
    pass


def input_to_output_path(input_path: str, model: str, seed: int = None):
    input_path_components = input_path[::-1].split("/", maxsplit=4)
    return f'{input_path_components[4][::-1]}/Models/{input_path_components[2][::-1]}/{input_path_components[1][::-1]}/{model}/{uuid4() if seed is None else seed}'


class Foo(Model):
    @tf.function
    def compute_mean(self, x, y):
        return x + y / 2.0


@main.command()
@click.argument('path', type=str)
@click.option('--model', '-m', type=click.Choice(['transe', 'complex']), required=True)
@click.option('--output', '-o', type=str, default=None)
@click.option('--seed', '-s', type=int, default=None)
@click.option('--tsv', '-t', type=bool, is_flag=True)
@click.option('--verbose', '-v', type=bool, is_flag=True)
@click.option('--remove', '-r', type=bool, is_flag=True)
def test(path: str, model: str, output: str = None, verbose: bool = False, seed: int = None, tsv: bool = False, remove: bool = False):
    if not tsv:
        print(f'Got input path "{path}"')

    if seed is not None:
        tf.random.set_seed(seed)

    # mean = Foo().compute_mean(2.0, 5.0)
    # print('foo')

    config = Config()

    # config.set_in_path("/home/zeio/OpenKE/benchmarks/FB15K/")
    config.set_in_path(path)
    config.set_work_threads(8)
    config.set_train_times(10)
    config.set_nbatches(2)
    config.set_alpha(0.1)
    config.set_margin(1.0)
    config.set_bern(0)
    config.set_dimension(10)
    config.set_ent_neg_rate(2)
    config.set_rel_neg_rate(0)
    config.set_opt_method("SGD")
    config.set_log_on(verbose)

    output_path = input_to_output_path(path, model, seed) if output is None else output
    # print(output_path)
    makedirs(output_path, exist_ok=True)
    config.set_export_files(f"{output_path}/model.vec.tf", 0)
    config.set_out_files(f"{output_path}/embedding.vec.json")

    config.set_test_link_prediction(True)

    config.init(as_tsv=tsv, verbose=verbose)

    # environ['CUDA_VISIBLE_DEVICES']='7'
    config.set_model(TransE if model == 'transe' else ComplEx, seed=seed)

    try:
        config.run()

        config.test(verbose=verbose, as_tsv=tsv)
    finally:
        if remove:
            rmtree(output_path)


if __name__ == '__main__':
    main()
