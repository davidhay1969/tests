#!/usr/bin/env bats
#
# Copyright (c) 2020 Ant Group
#
# SPDX-License-Identifier: Apache-2.0
#

load "${BATS_TEST_DIRNAME}/../../.ci/lib.sh"
load "${BATS_TEST_DIRNAME}/tests_common.sh"

setup() {
	export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
	pod_name="pod-oom"
	get_pod_config_dir
}

@test "Test OOM events for pods" {

	# Create test .yaml
	sed \
		-e "s|\${stress_image}|${stress_image}|" \
		-e "s/\${stress_image_pull_policy}/${stress_image_pull_policy}/" \
		"${pod_config_dir}/pod-oom.yaml" > "${pod_config_dir}/test_pod_oom.yaml"

	# Create pod
	kubectl create -f "${pod_config_dir}/test_pod_oom.yaml"

	# Check pod creation
	kubectl wait --for=condition=Ready --timeout=$timeout pod "$pod_name"

	# Check if OOMKilled
	cmd="kubectl get pods "$pod_name" -o yaml | yq r - 'status.containerStatuses[0].state.terminated.reason' | grep OOMKilled"

	waitForProcess "$wait_time" "$sleep_time" "$cmd"

	rm -f "${pod_config_dir}/test_pod_oom.yaml"
}

teardown() {
	# Debugging information
	kubectl describe "pod/$pod_name"
	kubectl get "pod/$pod_name" -o yaml

	kubectl delete pod "$pod_name"
}
