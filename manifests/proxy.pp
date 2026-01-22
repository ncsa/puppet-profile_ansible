# @summary Setup optional proxy user and config for ansible access
#
# Setup an optional proxy user that Ansible control nodes can use as a jump host for SSH port forwarding.
#
# @param username
#   Username that ansible proxy will connect as
#
# @param nodelist
#   Hash keyed by proxy node hostname, containing address and authorized_keys
#
# @param sshd_custom_cfg
#   Custom sshd configuration options for this user
#
# @example
#   include profile_ansible::proxy
class profile_ansible::proxy (
  Hash   $nodelist,
  Hash   $sshd_custom_cfg,
  String $username,
) {
  # ENSURE THE USER EXISTS
  user { $username:
    ensure     => present,
    comment    => 'Ansible proxy user',
    forcelocal => true,
    managehome => true,
    shell      => '/usr/sbin/nologin',
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

  # STATIC HARDENING OPTIONS APPLIED TO ALL KEYS
  $auth_key_security_options = [
    'no-agent-forwarding',
    'no-pty',
    'no-X11-forwarding',
    'command="/usr/sbin/nologin"',
  ]

  # BUILD EACH authorized_keys LINE
  $authorized_lines = $nodelist.map |String $node_name, Hash $node_data| {
    # VALIDATE: address MUST BE A SINGLE STRING
    if $node_data['address'] !~ String {
      fail("${module_name}::proxy: node '${node_name}' must have exactly one 'address' as String")
    }
    $address       = $node_data['address']
    $options_field = (["from=\"${address}\""] + $auth_key_security_options).join(',')
    # VALIDATE KEYS
    if $node_data['authorized_keys'] !~ Hash {
      fail("${module_name}::proxy: node '${node_name}' is missing 'authorized_keys' Hash")
    }
    # PRODUCE ONE LINE PER KEY FOR THIS NODE
    $node_data['authorized_keys'].map |String $key_id, Hash $key_data| {
      if $key_data['type'] == undef or $key_data['key'] == undef {
        fail("${module_name}::proxy: ${node_name}/${key_id} missing 'type' or 'key'")
      }
      $comment = $key_data['comment'] ? {
        String => $key_data['comment'],
        default => $key_id,
      }
      "${options_field} ${key_data['type']} ${key_data['key']} ${comment}"
    }
  }.flatten

  # MANAGE THE authorized_keys FILE VIA TEMPLATE
  file { "/home/${username}/.ssh/authorized_keys":
    ensure  => file,
    owner   => $username,
    group   => $username,
    mode    => '0600',
    content => epp("${module_name}/authorized_keys.epp", {
        'authorized_lines' => $authorized_lines,
    }),
    require => File["/home/${username}/.ssh"],
  }

  pam_access::entry { "Disable tty access for ${username}":
    user       => $username,
    origin     => 'tty',
    permission => '-',
    position   => '-1',
  }

  # Collect addresses -> flatten -> dedupe
  $node_ips = unique(flatten($nodelist.map |$n, $d| { $d['address'] }))

  sshd::allow_from { 'sshd allow from Ansible proxy nodes':
    hostlist                => $node_ips,
    users                   => [$username],
    groups                  => [$username],
    additional_match_params => $sshd_custom_cfg,
  }
}
