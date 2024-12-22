#  Copyright 2023 Google LLC

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at

#       https://www.apache.org/licenses/LICENSE-2.0

#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

SILENT:
.PHONY:
.DEFAULT_GOAL := help

# Load environment variables from .env file
TF_MODEL_URI :=
include .env
export

define PRINT_HELP_PYSCRIPT
import re, sys # isort:skip

matches = []
for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		matches.append(match.groups())

for target, help in sorted(matches):
    print("     %-25s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

PYTHON = python$(PYTHON_VERSION)

MODEL_ENV := "TORCH"

help: ## Print this help
	@echo
	@echo "  make targets:"
	@echo
	@$(PYTHON) -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

init-venv: ## Create virtual environment in venv folder
	@$(PYTHON) -m venv venv

init: init-venv ## Init virtual environment
	@./venv/bin/python3 -m pip install -U pip
	@$(shell sed "s|\$${BEAM_VERSION}|$(BEAM_VERSION)|g" requirements.prod.txt > requirements.txt)
	@./venv/bin/python3 -m pip install -r requirements.txt
	@./venv/bin/python3 -m pip install -r requirements.dev.txt
	@./venv/bin/python3 -m pre_commit install --install-hooks --overwrite
	@mkdir -p beam-output
	@echo "use 'source venv/bin/activate' to activate venv "
	@./venv/bin/python3 -m pip install -e .

format: ## Run formatter on source code
	@./venv/bin/python3 -m black --config=pyproject.toml .

lint: ## Run linter on source code
	@./venv/bin/python3 -m black --config=pyproject.toml --check .
	@./venv/bin/python3 -m flake8 --config=.flake8 .

clean-lite: ## Remove pycache files, pytest files, etc
	@rm -rf build dist .cache .coverage .coverage.* *.egg-info
	@find . -name .coverage | xargs rm -rf
	@find . -name .pytest_cache | xargs rm -rf
	@find . -name .tox | xargs rm -rf
	@find . -name __pycache__ | xargs rm -rf
	@find . -name *.egg-info | xargs rm -rf

clean: clean-lite ## Remove virtual environment, downloaded models, etc
	@rm -rf venv
	@echo "run 'make init'"

test: lint ## Run tests
	./venv/bin/pytest -s -vv --cov=my_project --cov-fail-under=50 tests/

run-direct: ## Run a local test with DirectRunner
	@rm -f beam-output/beam_test_out.txt
	time ./venv/bin/python3 -m my_project.run \
	--runner DirectRunner \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out.txt \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
	./venv/bin/python3 scripts/compare_results.py beam-output/beam_test_out.txt data/beam_test_out.txt

run-prism: ## Run a local test with PrismRunner
	@rm -f beam-output/beam_test_out_prism.txt
	time ./venv/bin/python3 -m my_project.run \
	--runner PrismRunner \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out_prism.txt \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
	./venv/bin/python3 scripts/compare_results.py beam-output/beam_test_out_prism.txt data/beam_test_out.txt

run-flink: ## Run a local test with FlinkRunner and LOOPBACK
	@rm -f beam-output/beam_test_out_flink.txt
	time ./venv/bin/python3 -m my_project.run \
	--runner FlinkRunner \
	--flink_conf_dir data \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out_flink.txt \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
	./venv/bin/python3 scripts/compare_results.py beam-output/beam_test_out_flink.txt data/beam_test_out.txt

run-portable-flink: ## Run a local test with PortableRunner, LOOPBACK, and one embedded Flink cluster
	@rm -f beam-output/beam_test_out_portable_flink.txt
	-docker stop flink_job_service
	docker run --net=host --rm -d -v $(PWD)/data:/flink-conf --name flink_job_service apache/beam_flink$(FLINK_VERSION)_job_server:latest --flink-conf-dir /flink-conf
	time ./venv/bin/python3 -m my_project.run \
	--runner PortableRunner \
	--job_endpoint localhost:8099 \
	--environment_type LOOPBACK \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out_portable_flink.txt \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
	./venv/bin/python3 scripts/compare_results.py beam-output/beam_test_out_portable_flink.txt data/beam_test_out.txt
	docker stop flink_job_service

run-portable-flink-local: ## Run a local test with PortableRunner, LOOPBACK, and a local Flink cluster
	@rm -f beam-output/beam_test_out_portable_flink_local.txt
	@cp -f data/flink-conf-local.yaml $(FLINK_LOCATION)/conf/flink-conf.yaml
	-$(FLINK_LOCATION)/bin/stop-cluster.sh
	$(FLINK_LOCATION)/bin/start-cluster.sh
	-docker stop flink_job_service
	docker run --net=host --rm -d --name flink_job_service apache/beam_flink$(FLINK_VERSION)_job_server:latest --flink-master=localhost:8081
	time ./venv/bin/python3 -m my_project.run \
	--runner PortableRunner \
	--job_endpoint localhost:8099 \
	--environment_type LOOPBACK \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out_portable_flink_local.txt \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
	./venv/bin/python3 scripts/compare_results.py beam-output/beam_test_out_portable_flink_local.txt data/beam_test_out.txt
	docker stop flink_job_service
	$(FLINK_LOCATION)/bin/stop-cluster.sh

docker-cpu: ## Build a custom docker image with Pytorch
	$(shell sed "s|\$${BEAM_VERSION}|$(BEAM_VERSION)|g; s|\$${PYTHON_VERSION}|$(PYTHON_VERSION)|g" ${DOCKERFILE_TEMPLATE} > Dockerfile)
	docker build --platform linux/amd64 -t $(LOCAL_CONTAINER_IMAGE) -f Dockerfile .

run-portable-flink-worker-local: ## Run a local test with PortableRunner, DOCKER, and a local Flink cluster
	@rm -f beam-output/beam_test_out_portable_flink_worker_local.txt
	@cp -f data/flink-conf-local.yaml $(FLINK_LOCATION)/conf/flink-conf.yaml
	-$(FLINK_LOCATION)/bin/stop-cluster.sh
	@rm -f $(FLINK_LOCATION)/log/*
	$(FLINK_LOCATION)/bin/start-cluster.sh
	-docker stop flink_job_service
	docker run --net=host --rm -d -v /tmp:/tmp --name flink_job_service apache/beam_flink$(FLINK_VERSION)_job_server:latest --flink-master=localhost:8081
	time ./venv/bin/python3 -m my_project.run \
	--runner PortableRunner \
	--job_endpoint localhost:8099 \
	--environment_type DOCKER \
	--environment_config $(LOCAL_CONTAINER_IMAGE) \
	--experiments disable_logging_submission_environment \
	--setup_file ./setup.py \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
	docker stop flink_job_service
	$(FLINK_LOCATION)/bin/stop-cluster.sh

push-docker-cpu: ## Push a custom docker image with Pytorch CPU to AR
	docker tag $(LOCAL_CONTAINER_IMAGE) $(HARNESS_IMAGES_TO_PULL)
	docker push $(HARNESS_IMAGES_TO_PULL)

create-flink-cluster: ## Create a flink cluster using Dataproc
	cd scripts; ./dataproc_flink_cluster.sh create; cd ..

remove-flink-cluster: ## Remove a flink cluster using Dataproc
	cd scripts; ./dataproc_flink_cluster.sh delete; cd ..

run-portable-flink-cluster: ## Run a local test with PortableRunner and a Dataproc Flink cluster
	time ./venv/bin/python3 -m my_project.run \
	--runner PortableRunner \
	--job_endpoint localhost:8099 \
	--environment_type DOCKER \
	--environment_config $(HARNESS_IMAGES_TO_PULL) \
	--experiments disable_logging_submission_environment \
	--setup_file ./setup.py \
	--input gs://xqhu-ml/test-flink/openimage_10.txt \
	--output gs://xqhu-ml/test-flink/openimage_10.txt/output \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)