This directory contains useful scripts.

## compare_results.py
This script compares two TXT files with two columns (file name and class number) separated by commas, ignoring the order of rows. It will issue errors if the files do not match.

**Usage:**
```bash
python compare_results.py <file1.txt> <file2.txt>
```

## dataproc_flink_cluster.sh
This script facilitates the management of Flink clusters on Google Cloud Dataproc, enabling the creation, restart, and deletion of these clusters. It's based on the implementation found in the Apache Beam repository at https://github.com/apache/beam/blob/master/.test-infra/dataproc/flink_cluster.sh. Notably, the script retrieves the Beam job's Flink server Docker image on the Dataproc master node and executes it. Additionally, it runs the Beam Python SDK harness by downloading the Beam Python Docker image onto the cluster nodes, which therefore require Docker to be installed and have internet access.

Currently, Dataproc supports Flink 1.17 (https://cloud.google.com/dataproc/docs/concepts/versioning/dataproc-release-2.2).

**Prerequisites:**
- Google Cloud SDK installed and configured.
- Necessary environment variables set (see script for details).

**Usage:**
```bash
CLUSTER_NAME=<your_cluster_name> \
GCS_BUCKET=gs://<your_gcs_bucket>/flink \
# ... other environment variables ... \
./dataproc_flink_cluster.sh create|restart|delete
```