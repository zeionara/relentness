# relentness

Knowledge graph models manipulator which allows to perform various evaluations of provided embedders. Currently there is only an incomplete support for fetching **wikidata** triples and saving them in the format acceptable for the OpenKE toolkit (see examples of the generated datasets in the folder `Assets/Demo`).

# Usage

To generate a sample from wikidata using default params, execute the following command:

```
swift build && ./.build/debug/relentness Assets/Demo
```

The generated files will be saved in the directory `Assets/Demo`. To list all available option for the `sample` subcommand, please, use the following call:

```
./.build/debug/relentness sample --help
```

To test a model on a given dataset:

```
python -m relentness test-transe ./Assets/Corpora/Demo/0000/
```

