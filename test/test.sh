#!/bin/bash

set -euo pipefail

docker build -t basisai/workload-standard-testee -f ../Dockerfile ../.
docker build -t basisai/workload-standard-tester -f Dockerfile.test .
docker run basisai/workload-standard-tester
