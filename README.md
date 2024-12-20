# beam-ml-flink

A simple test Beam ML pipeline using FlinkRunner.


## Prerequisites

* Python 3

Check `.env` to change based on your need.

## Init and Test

```bash
make init  # Install dependencies.
make test  # Run unit tests.
```

## Running the Pipeline Locally

You can execute the pipeline using different local runners:

* Direct Runner

```bash
make run-direct
```

* Prism Runner

```bash
make run-prism
```

* Flink Runner with LOOPBACK

```bash
make run-flink
```

## Links

* https://github.com/jaehyeon-kim/beam-demos/tree/master/beam-pipelines
* https://beam.apache.org/documentation/runners/flink/
