# @summary Setup local ansible user
#
# Setup a local ansible user that Ansible control node can connect as.
#
# @param username
#   Username that ansible controller will connect as
#
# @param authorized_keys
#   Hash of keys to be used by puppetlabs-sshkeys_core
#   See https://forge.puppet.com/modules/puppetlabs/sshkeys_core
#   The 'user' parameter can be omitted as it uses $username
#
# @param control_nodelist
#   Array of IP addresses of the Ansible control nodes
#   Login access for this user is limited to these IP addresses
#
# @param sshd_custom_cfg
#   Custom sshd configuration options for this user
#
# @param sudo_custom_cfg
#   Custom sudo configuration options for this user
#
# @example
#   include profile_ansible
class profile_ansible (
  Hash             $authorized_keys,
  Array[String, 1] $control_nodelist,
  Hash             $sshd_custom_cfg,
  String           $sudo_custom_cfg,
  String           $username,
) {
  # ENSURE THE USER EXISTS
  user { $username:
    ensure     => present,
    comment    => 'Ansible client user',
    forcelocal => true,
    managehome => true,
    shell      => '/bin/bash',
    password   => '!!',
  }

  # CREATE .ssh DIRECTORY
  file { "/home/${username}/.ssh":
    ensure  => directory,
    owner   => $username,
    group   => $username,
    mode    => '0700',
    require => [
      User[$username],
    ],
  }

  # GENERATE THE 'from' OPTION STRING FROM control_nodelist
  $from_option = "from=\"${control_nodelist.join(',')}\""

  # LOOP ACROSS authorized_keys HASH
  $authorized_keys.each |$key_id, $key_data| {
    ssh_authorized_key { "${username}_${key_id}":
      ensure  => present,
      user    => $username,
      type    => $key_data['type'],
      key     => $key_data['key'],
      options => $from_option,
      require => [
        User[$username],
        File["/home/${username}/.ssh"],
      ],
    }
  }

  # THE FOLLOWING WILL CREATE CONFIGS FOR sshd, access.conf, iptables
  ::sshd::allow_from { 'sshd allow from Ansible control nodes':
    hostlist                => $control_nodelist,
    users                   => [$username],
    groups                  => [$username],
    additional_match_params => $sshd_custom_cfg,
  }

  pam_access::entry { "Allow sudo for ${username}":
    user       => $username,
    origin     => 'LOCAL',
    permission => '+',
    position   => '-1',
  }

  sudo::conf { "sudo_for_${username}":
    ensure   => 'present',
    priority => 10,
    content  => $sudo_custom_cfg,
  }
}
