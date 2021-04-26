# Working combination (so far)
- Fedora CoreOS 33.20210217.3.0
- OKD 4.6.0-0.okd-2021-02-14-205305

## Links for Fedora CoreOS
https://builds.coreos.fedoraproject.org/browser?stream=stable

### ISO
- Live ISO: fedora-coreos-33.20210217.3.0-live.x86_64.iso https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/33.20210217.3.0/x86_64/fedora-coreos-33.20210217.3.0-live.x86_64.iso

### PXE
- Live Kernel: fedora-coreos-33.20210217.3.0-live-kernel-x86_64 https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/33.20210217.3.0/x86_64/fedora-coreos-33.20210217.3.0-live-kernel-x86_64
- Live Initramfs: fedora-coreos-33.20210217.3.0-live-initramfs.x86_64.img https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/33.20210217.3.0/x86_64/fedora-coreos-33.20210217.3.0-live-initramfs.x86_64.img
- Live Rootfs: fedora-coreos-33.20210217.3.0-live-rootfs.x86_64.img https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/33.20210217.3.0/x86_64/fedora-coreos-33.20210217.3.0-live-rootfs.x86_64.img


# master nodes with vmxnet3 driver
```
    sudo ethtool -K ens192 tx-udp_tnl-segmentation off
    sudo ethtool -K ens192 tx-udp_tnl-csum-segmentation off
```

## File: `/etc/NetworkManager/dispatcher.d/99-vsphere-disable-tx-udp-tnl`
> Reference: https://github.com/openshift/machine-config-operator/pull/2495/files

```
    #!/bin/bash
    # Workaround:
    # https://bugzilla.redhat.com/show_bug.cgi?id=1941714
    # https://bugzilla.redhat.com/show_bug.cgi?id=1935539
    driver=$(nmcli -t -m tabular -f general.driver dev show "${DEVICE_IFACE}")
    if [[ "$2" == "up" && "${driver}" == "vmxnet3" ]]; then
      logger -s "99-vsphere-disable-tx-udp-tnl triggered by ${2} on device ${DEVICE_IFACE}."
      ethtool -K ${DEVICE_IFACE} tx-udp_tnl-segmentation off
      ethtool -K ${DEVICE_IFACE} tx-udp_tnl-csum-segmentation off
    fi
```

## File: `install-config.yaml`

From: `networkType: OpenShiftSDN`

To: `networkType: OVNKubernetes`
```
    ...
    networking:
      clusterNetwork:
      - cidr: 10.128.0.0/14
        hostPrefix: 23
      networkType: OVNKubernetes
      serviceNetwork:
      - 172.30.0.0/16
    ...
```

# export kubeconfig key
```
    export KUBECONFIG=/usr/share/nginx/html/baremetal/auth/kubeconfig
```

# Approve CSR
```
    oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

# Check for operator status
```
    watch -s 5 oc get clusteroperators
```
