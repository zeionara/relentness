import ArgumentParser

struct Relentness: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Knowledge graph models manipulator which allows to perform various evaluations of provided embedders",
        version: "0.0.7",
        subcommands: [
            GenerateSample.self, Test.self, TestWithSeeds.self, TestAllFolds.self, HyperSearch.self,
            ExploreDataset.self, ExportDataset.self, CompareModels.self, EvaluateDataset.self, CompareDatasets.self
        ],
        defaultSubcommand: GenerateSample.self
    )
}

Relentness.main()

