#!/bin/sh

#
# Determined Installation and Deployment Validation Tests
# Experiments, Tasks
#
# This script runs one experiment for each combination of model type and resource
# configuration below:
#
#   Model Type:
#      1. Core API
#      2. PyTorch
#      3. DeepSpeed
#
#   Resource Configuration:
#      1. single node, single GPU
#      2. single node, multi  GPU (distributed)
#      3. multi  node, multi  GPU (distributed)
# 

set -e

readonly tmpdir="$(mktemp -d)"
echo "created temporary directory ${tmpdir}" >&2

on_exit() {
    echo "removing temporary directory: ${tmpdir}" >&2
    rm -rf "${tmpdir}"
    echo "exiting health checks" >&2
}

trap on_exit EXIT

if [ -z "${DETVALID_SLOTS_PER_NODE}" ]; then
    echo "ERROR: environment variable DETVALID_SLOTS_PER_NODE not set." >&2
fi

core_api="./examples/tutorials/core_api"
core_api_single_config="${core_api}/0_start.yaml"
core_api_distributed_config="${core_api}/4_distributed.yaml"

pytorch="./examples/tutorials/mnist_pytorch"
pytorch_single_config="${pytorch}/const.yaml"
pytorch_distributed_config="${pytorch}/distributed.yaml"

deepspeed="./examples/deepspeed/cifar10_moe"
deepspeed_single_config="${deepspeed}/moe.yaml"
deepspeed_distributed_config="${deepspeed}/moe.yaml"

mgpu_mnode_num_slots=$(( ${DETVALID_SLOTS_PER_NODE} * 2 ))


# ====================
# Experiment: Core API
# ====================

# COM.EXP.CORE_API.SGPU_SNODE
det e create --test-mode "${core_api_single_config}" "${core_api}"

# COM.EXP.CORE_API.MGPU_SNODE
det e create --test-mode --config "resources.slots_per_trial=2" "${core_api_distributed_config}" "${core_api}"

# COM.EXP.CORE_API.MGPU_MNODE
det e create --test-mode --config "resources.slots_per_trial=${mgpu_mnode_num_slots}" "${core_api_distributed_config}" "${core_api}"

# ===================
# Experiment: PyTorch
# ===================

# COM.EXP.PYTORCH.SGPU_SNODE
det e create --test-mode "${pytorch_single_config}" "${pytorch}"

# COM.EXP.PYTORCH.MGPU_SNODE
det e create --test-mode --config "resources.slots_per_trial=2" "${pytorch_distributed_config}" "${pytorch}"

# COM.EXP.PYTORCH.MGPU_MNODE
det e create --test-mode --config "resources.slots_per_trial=${mgpu_mnode_num_slots}" "${pytorch_distributed_config}" "${pytorch}"

# =====================
# Experiment: DeepSpeed
# =====================

# COM.EXP.DEEPSPEED.SGPU_SNODE
det e create --test-mode "${deepspeed_single_config}" "${deepspeed}"

# COM.EXP.DEEPSPEED.MGPU_SNODE
det e create --test-mode --config "resources.slots_per_trial=2" "${deepspeed_distributed_config}" "${deepspeed}"

# COM.EXP.DEEPSPEED.MGPU_MNODE
det e create --test-mode --config "resources.slots_per_trial=${mgpu_mnode_num_slots}" "${deepspeed_distributed_config}" "${deepspeed}"

# =====
# Tasks
# =====

# COM.TSK.RUN_CMD
det cmd run echo foobar | grep foobar

# COM.TSK.START_SHELL
shell_id="$(echo exit           # disconnect right after connecting
        | det shell start 2>&1  # use the first returned UUID as the shell ID
        | grep --max-count=1 -Eo '[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}')"

# confirm from master a successful connect and disconnect
# TODO: false positive if "disconnected by user" from previous runs. find a better check
det shell logs "${shell_id}" | grep "disconnected by user"
det shell kill "${shell_id}"
