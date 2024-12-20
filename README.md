# beam-ml-flink

A simple test Beam ML pipeline using FlinkRunner.


## Prerequisites

* Python 3
* Linux (flink-related tests with PortableRunner do not work on Mac or Windows)

Check `.env` to change based on your need.

## Init and Test

```bash
make init  # Install dependencies.
make test  # Run unit tests.
```

## Running the Pipeline Locally

You can execute the pipeline using different runners locally:

* Direct Runner

```bash
make run-direct
```

* Prism Runner

```bash
make run-prism
```

* Flink Runner with LOOPBACK

Note `data/flink-conf.yaml` is used here to optimize the flink configurations.

```bash
make run-flink
```

* Portable Runner with Flink and LOOPBACK

Note this only works with Linux and docker is required to run a Flink job service locally.

```bash
make run-portable-flink
```

## Links

* https://github.com/jaehyeon-kim/beam-demos/tree/master/beam-pipelines
* https://beam.apache.org/documentation/runners/flink/
* https://beam.apache.org/documentation/runtime/sdk-harness-config/
