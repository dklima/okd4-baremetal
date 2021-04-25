#!/usr/bin/env bash

BAREMETAL="/usr/share/nginx/html/baremetal"
export BAREMETAL

WHOAMI="$(whoami)"
export WHOAMI

if test "${WHOAMI}" = 'root'; then echo 'Use sudo'; exit 1; fi
if test -z "${BAREMETAL}"; then exit 1; fi

sudo rm -rf "${BAREMETAL}"
sudo mkdir "${BAREMETAL}"
sudo chown "${WHOAMI}" "${BAREMETAL}"

if test -f "./install-config.yaml"; then
  cp -v "./install-config.yaml" "${BAREMETAL}"
  openshift-install create manifests --dir="${BAREMETAL}"
  sed -i 's/mastersSchedulable: true/mastersSchedulable: False/' "${BAREMETAL}/manifests/cluster-scheduler-02-config.yml"

  openshift-install create ignition-configs --dir="${BAREMETAL}"

  chmod 644 "${BAREMETAL}"/auth/*
  chmod 755 "${BAREMETAL}"/auth
  chmod 644 "${BAREMETAL}"/*ign
  chmod 644 "${BAREMETAL}"/*json
fi

export KUBECONFIG=/usr/share/nginx/html/baremetal/auth/kubeconfig

