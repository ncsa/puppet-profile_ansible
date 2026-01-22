# profile_ansible

![pdk-validate](https://github.com/ncsa/puppet-profile_ansible/workflows/pdk-validate/badge.svg)
![yamllint](https://github.com/ncsa/puppet-profile_ansible/workflows/yamllint/badge.svg)

Configure a node to be managed by Ansible.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with profile_ansible](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Dependencies](#dependencies)
1. [Reference](#reference)

## Description

Configure a node to be managed by Ansible:
- setup a local user, e.g. `ansible`
- allow ssh into the node from an Ansible control node via an ssh publickey
- allow the local ansible user to sudo for root privileges

## Setup
Include profile_ansible in a puppet profile file:
```
include ::profile_ansible
```

## Usage

You will need to provide the following parameters:
* `control_nodelist`

`control_nodelist` is a Hash containing per-node `address` and `authroized_keys`.
Refer to [REFERENCE.md](REFERENCE.md) for an example.

## Dependencies

* [ncsa/pam_access](https://github.com/ncsa/puppet-pam_access)
* [ncsa/sshd](https://github.com/ncsa/puppet-sshd)
* [saz/sudo](https://forge.puppet.com/modules/saz/sudo)

## Reference

See: [REFERENCE.md](REFERENCE.md)
