#!/bin/sh

if [ -z "${DET_MASTER}" ]; then
    echo "ERROR: environment variable DET_MASTER is not set" >&2
    return 1
fi

readonly tmpdir="$(mktemp -d)"
echo "created temporary directory ${tmpdir}" >&2

on_exit() {
    echo "removing temporary directory: ${tmpdir}" >&2
    rm -rf "${tmpdir}"
    echo "exiting health checks" >&2
}

trap on_exit EXIT

core_api="${DET_HEALTH_CORE_API:-./examples/tutorials/core_api}"
core_api_single_config="${DET_HEALTH_CORE_API_SINGLE_CONFIG:-${core_api}/0_start.yaml}"
core_api_distributed_config="${DET_HEALTH_CORE_API_DISTRIBUTED_CONFIG:-${core_api}/4_distributed.yaml}"

mnist_pytorch="${DET_HEALTH_MNIST_PYTORCH:-./examples/tutorials/mnist_pytorch}"
mnist_pytorch_single_config="${DET_HEALTH_MNIST_PYTORCH_SINGLE_CONFIG:-${mnist_pytorch}/const.yaml}"
mnist_pytorch_distributed_config="${DET_HEALTH_MNIST_PYTORCH_DISTRIBUTED_CONFIG:-${mnist_pytorch}/distributed.yaml}"

slots_per_node="${DET_HEALTH_SLOTS_PER_NODE:-}"

# COMMON TESTS
#
# Prerequisites: 
#   - `det` command is available and properly configured to connect to `DET_MASTER`.
#

# COM.EXP.SINGLE_GPU
test_10() {
    det e create --test-mode "${core_api_single_config}" "${core_api}"
}

# COM.EXP.MULTI_GPU_SNODE
test_20() {
    det e create --test-mode --config "resources.slots_per_trial=2" "${core_api_distributed_config}" "${core_api}"
}

# COM.EXP.MULTI_GPU_MNODE
test_30() {
    if [ ! ${slots_per_node} -gt 1 ]; then
        echo "ERROR: set \$DET_HEALTH_SLOTS_PER_NODE > 1" >&2
        return 1
    fi

    slots=$(( ${slots_per_node} * 2 ))
    det e create --test-mode --config "resources.slots_per_trial=${slots}" "${core_api_distributed_config}" "${core_api}"
}

# COM.EXP.SINGLE_GPU_PT
test_40() {
    det e create --test-mode "${mnist_pytorch_single_config}" "${mnist_pytorch}"
}

# COM.EXP.MULTI_GPU_SNODE_PT
test_50() {
    det e create --test-mode --config "resources.slots_per_trial=2" "${mnist_pytorch_distributed_config}" "${mnist_pytorch}"
}

# COM.EXP.MULTI_GPU_MNODE_PT
test_60() {
    if [ ! ${slots_per_node} -gt 1 ]; then
        echo "ERROR: set \$DET_HEALTH_SLOTS_PER_NODE > 1" >&2
        return 1
    fi

    slots=$(( ${slots_per_node} * 2 ))
    det e create --test-mode --config "resources.slots_per_trial=${slots}" "${mnist_pytorch_distributed_config}" "${mnist_pytorch}"
}

# COM.TSK.RUN_CMD
test_70() {
    det cmd run echo foobar | grep foobar
}

# COM.TSK.START_SHELL
test_80() {
    shell_id="$(echo exit
        | det shell start 2>&1
        | grep --max-count=1 -Eo '[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}')"
    det shell logs "${shell_id}" | grep "disconnected by user"
    det shell kill "${shell_id}"
}

test_90() {
    curl $DET_MASTER/agents >"${tmpdir}/agents.json"
    <"${tmpdir}/agents.json" jq '[.[] | select(.resource_pool == "compute-pool")] | length'
}

# pytorch lightning
