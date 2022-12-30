import Swat

struct Config: ConfigWithDefaultKeys, RootConfig {
    let corpus: Corpus
    let sampler: Sampler_
    let evaluator: Evaluator

    let model: Model_
    let trainer: Trainer
    let optimizer: Optimizer_
    let checkpoint: Checkpoint

    let name: String
}
