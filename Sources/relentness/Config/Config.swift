import Swat

public struct Config: ConfigWithDefaultKeys, RootConfig {
    let corpus: Corpus
    let sampler: Sampler_
    let evaluator: Evaluator

    let model: Model_
    let trainer: Trainer
    let optimizer: Optimizer_
    let checkpoint: Checkpoint

    public let name: String

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyKey.self)

        try container.encode(corpus, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("corpus")))
        try container.encode(sampler, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("sampler")))
        try container.encode(evaluator, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("evaluator")))

        try container.encode(model, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("model")))
        try container.encode(trainer, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("trainer")))
        try container.encode(optimizer, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("optimizer")))
        try container.encode(checkpoint, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("checkpoint")))

        try container.encode(name, forKey: AnyKey(stringValue: encoder.userInfo.postProcess("name")))
    }

    func appending(cvSplitIndex: Int) -> Config {
        return Config(
            corpus: corpus.appending(cvSplitIndex: cvSplitIndex),
            sampler: sampler,
            evaluator: evaluator,

            model: model,
            trainer: trainer,
            optimizer: optimizer,
            checkpoint: checkpoint,
            
            name: name
        )
    }
}
