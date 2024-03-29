import os
import random
# from os import makedirs
# from shutil import rmtree
# from uuid import uuid4

import click
import numpy as np
import tensorflow as tf
# from keras.models import Model

from openke.config import Config  # , ModelConfig, OptimizerConfig, TrainConfig, CheckpointConfig
# from openke.models import TransE, ComplEx
# from openke.meager import Adapter as MeagerAdapter, CorpusConfig, SamplerConfig, EvaluatorConfig
from openke.enum import SubsetType  # Pattern, Model, Optimizer, EvaluationTask

from openke.trainer import Trainer
from openke.evaluator import Evaluator

# from .utils.files import input_to_output_model_path


@click.group()
def main():
    pass


# class Foo(Model):
#     @tf.function
#     def compute_mean(self, x, y):
#         return x + y / 2.0


# @click.option('--neg-rate', '-n', type=int, default=2)
@main.command()
@click.argument('path', type=str)  #
# @click.option('--model', '-m', type=click.Choice(['transe', 'complex']), required=True)  #
@click.option('--verbose', '-v', type=bool, is_flag=True)  #
@click.option('--child', '-c', type=bool, is_flag=True)  #
# @click.option('--output', '-o', type=str, default=None)  #
# @click.option('--images', '-i', type=str, default=None)
@click.option('--seed', '-s', type=int, default=None)  #
# @click.option('--as-tsv', '-t', type=bool, is_flag=True)  #
# @click.option('--remove', '-r', type=bool, is_flag=True)  #
# @click.option('--validate', '-val', type=bool, is_flag=True)  #
# @click.option('--n-epochs', '-e', type=int, default=100)  #
# @click.option('--batch-size', '-b', type=int, default=3)  #
# @click.option('--margin', '-ma', type=float, default=5.0)  #
# @click.option('--alpha', '-a', type=float, default=0.1)  #
# @click.option('--hidden-size', '-hs', type=int, default=10)  #
# @click.option('--lmbda', '-l', type=float, default=0.0)  #
# @click.option('--optimizer', '-opt', type=click.Choice(["adagrad", "adadelta", "adam", "sgd"]), default="sgd")  #
# @click.option('--task', '-tsk', type=click.Choice(["link-prediction", "triple-classification"]), default="link-prediction")  #
# @click.option('--bern', '-brn', type=bool, is_flag=True)  #
# @click.option('--relation-dimension', '-rd', type=int, default=None)  #
# @click.option('--entity-dimension', '-ed', type=int, default=None)  #
# @click.option('--patience', '-p', type=int, default=None)  #
# @click.option('--min-delta', '-md', type=float, default=None)  #
# @click.option('--relation-neg-rate', '-rn', type=int, default=0)  #
# @click.option('--entity-neg-rate', '-en', type=int, default=1)  #
# @click.option('--n-workers', '-nw', type=int, default=8)  #
# @click.option('--n-export-steps', '-nes', type=int, default=0)  #
# @click.option('--import-path', '-ip', type=str, default=None)  #
# @click.option('--export-path', '-ep', type=str, default=None)  #
# @click.option('--visualize', '-vis', type=bool, is_flag=True)
def test(
    path: str,
    # model: str, output: str = None,
    # images: str = None,
    verbose: bool = False, child: bool = False, seed: int = None,
    # n_epochs: int = 10, batch_size: int = 2, margin: float = 5.0, alpha: float = 0.1, hidden_size: int = 10,
    # as_tsv: bool = False, remove: bool = False,
    # validate: bool = False,  # neg_rate: int = 2,
    # lmbda: float = 0.0, optimizer: str = "sgd", task: str = 'link-prediction', bern: bool = False, relation_dimension: int = None, entity_dimension: int = None, patience: int = None,
    # min_delta: float = None, relation_neg_rate: int = 0, entity_neg_rate: int = 1, n_workers: int = 8, n_export_steps: int = 0,
    # import_path: str = None, export_path: str = None, visualize: bool = False
):
    # print("ok")
    # if not as_tsv:
    #     print(f'Got input path "{path}"')

    if seed is not None:
        os.environ['PYTHONHASHSEED'] = str(seed)
        tf.random.set_seed(seed)
        random.seed(seed)
        np.random.seed(seed)

        tf.config.threading.set_inter_op_parallelism_threads(1)
        tf.config.threading.set_intra_op_parallelism_threads(1)

        os.environ['TF_DETERMINISTIC_OPS'] = '1'
        os.environ['TF_CUDNN_DETERMINISTIC'] = '1'

    # # mean = Foo().compute_mean(2.0, 5.0)
    # # print('foo')

    config = Config.from_file(path)

    # config = Config(
    #     MeagerAdapter(
    #         '/usr/lib/libmeager_python.so',
    #         CorpusConfig(
    #             path = path,
    #             enable_filter = False,
    #             drop_filter_duplicates = True
    #         ),
    #         SamplerConfig(
    #             pattern = Pattern.NONE,
    #             n_observed_triples_per_pattern_instance = 1,
    #             bern = bern,
    #             cross_sampling = False,
    #             n_workers = n_workers
    #         ),
    #         EvaluatorConfig(
    #             task = EvaluationTask.LINK_PREDICTION
    #         )
    #     ),
    #     ModelConfig(
    #         model = Model(model),
    #         hidden_size = hidden_size
    #     ),
    #     OptimizerConfig(
    #         optimizer = Optimizer(optimizer),
    #         alpha = alpha
    #     ),
    #     early_stopping_config = None,
    #     checkpoint_config = CheckpointConfig(
    #         root = input_to_output_model_path(path, model, seed) if output is None else output,
    #         frequency = 10
    #     )
    # )

    # config = Config(Task.LINK_PREDICTION)
    # config.set_corpus_path(path)

    # config.set_drop_filter_duplicates(True)
    # config.set_drop_pattern_duplicates(True)
    # config.set_enable_filter(False)

    # config.set_n_epochs(n_epochs)
    # config.set_batch_size(batch_size)

    # config.set_bern(bern)
    # config.set_cross_sampling(False)
    # config.set_n_observed_triples_per_pattern_instance(1)
    # config.set_n_workers(n_workers)
    # config.set_pattern(Pattern.NONE)

    # config.set_entity_negative_rate(entity_neg_rate)
    # config.set_relation_negative_rate(relation_neg_rate)

    # model-specific

    # config.set_alpha(alpha)
    # config.optimizer_type = Optimizer(optimizer)
    # config.set_model(Model(model))

    # config.set_margin(margin)
    # config.set_hidden_size(hidden_size)

    # # config.set_in_path("/home/zeio/OpenKE/benchmarks/FB15K/")
    # config.set_in_path(path)
    # config.set_alpha(alpha)
    # config.set_dimension(hidden_size)
    # config.set_log_on(verbose)

    # config.set_lmbda(lmbda)
    # config.set_opt_method(optimizer)
    # if relation_dimension is not None:
    #     config.set_rel_dimension(relation_dimension)
    # if entity_dimension is not None:
    #     config.set_ent_dimension(entity_dimension)
    # config.set_ent_neg_rate(entity_neg_rate)
    # config.set_rel_neg_rate(relation_neg_rate)
    # config.set_import_files(import_path)
    # config.set_export_files(export_path, steps=n_export_steps)

    # assert patience is None and min_delta is None or patience is not None and min_delta is not None, "Patience and min-delta parameters must either both be provided either both omitted"
    # if patience is not None:
    #     config.set_early_stopping((patience, min_delta))

    # print(output_path)
    # images_path = input_to_images_path(path, model, seed) if images is None else images
    # # print(output_path)
    # makedirs(output_path, exist_ok=True)
    # config.set_export_files(f"{output_path}/model.vec.tf", 0)
    # config.set_out_files(f"{output_path}/embedding.vec.json")

    # if task == "link-prediction":
    #     config.set_test_link_prediction(True)
    # else:
    #     raise NotImplementedError("Triple classification task is not supported yet")

    # config.init(as_tsv=as_tsv, verbose=verbose)

    # # environ['CUDA_VISIBLE_DEVICES']='7'

    # try:
    df = Trainer(config).train(
        seed = seed,
        load = False,
        verbose = verbose
    )

    if verbose:
        print(df)

    Evaluator(config).test(SubsetType.TEST, verbose, child)

    # print(config.trainModel.entity_embeddings)

    #     if validate:
    #         config.validate(verbose=verbose, as_tsv=as_tsv)
    #     else:
    #         config.test(verbose=verbose, as_tsv=as_tsv)
    # finally:
    #     if remove:
    #         rmtree(output_path)

    # if visualize and getattr(config.trainModel, 'visualize_entity_embeddings') is not None:
    #     config.trainModel.visualize_entity_embeddings(model='pca', path=images_path)
    #     config.trainModel.visualize_relationship_embeddings(model='pca', path=images_path)


if __name__ == '__main__':
    main()
