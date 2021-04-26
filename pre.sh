#!/usr/bin/env bash

OKD4_DIR='/tmp/okd4'
OKD4_VERSION='4.7.0-0.okd-2021-04-24-103438'
GITHUB_RELEASE_URL="https://github.com/openshift/okd/releases/download/${OKD4_VERSION}"
OKD4_CLIENT="openshift-client-linux-${OKD4_VERSION}.tar.gz"
OKD4_INSTALL="openshift-install-linux-${OKD4_VERSION}.tar.gz"
WHOAMI="$(whoami)"

function main() {
  validation
  prepare
  install_packages
  enable_services
  selinux
  open_firewall_ports
}

function validation() {
  if ! test "${WHOAMI}" = 'root'; then
    echo "Need to run as root"
    exit 1
  fi
}

function install_packages() {
  dnf -y update
  dnf -y install bind bind-utils haproxy nginx tftp-server wget
}

function enable_services() {
  systemctl enable named
  systemctl enable nginx
  systemctl enable tftp
  systemctl enable haproxy
}

function open_firewall_ports() {
  firewall-cmd --permanent --add-port=53/udp
  firewall-cmd --permanent --add-port=6443/tcp
  firewall-cmd --permanent --add-port=22623/tcp
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --permanent --add-port=8080/tcp
  firewall-cmd --reload
}

function selinux() {
  setsebool -P haproxy_connect_any 1
  setsebool -P httpd_read_user_content 1
}

function create_dir() {
  if ! test -d "${OKD4_DIR}"; then
    mkdir "${OKD4_DIR}"
  fi
}

function clear_dir() {
  if test -d "${OKD4_DIR}"; then
    rm -f "${OKD4_DIR}"/*
  fi
}

function download_okd4() {
  cd "${OKD4_DIR}" || exit 1
  if ! test -f "${OKD4_CLIENT}" && ! test -f "${OKD4_INSTALL}"; then
    wget "${GITHUB_RELEASE_URL}/${OKD4_CLIENT}" "${GITHUB_RELEASE_URL}/${OKD4_INSTALL}"
  fi
  tar zxvf "${OKD4_DIR}"/"${OKD4_CLIENT}" -C "${OKD4_DIR}"
  tar zxvf "${OKD4_DIR}"/"${OKD4_INSTALL}" -C "${OKD4_DIR}"
}

function install_okd4_files() {
  mv "${OKD4_DIR}"/{kubectl,oc,openshift-install} "/usr/local/bin/"
}

function prepare() {
  create_dir
  clear_dir
  download_okd4
  if test "${?}" -eq 0; then install_okd4_files; fi
}

main

