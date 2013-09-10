# manage strongswan services
class strongswan::base {

  package{'strongswan':
    ensure => installed,
    require => Package['monkeysphere','gnutls-utils'];
  } -> exec{
    'ipsec_privatekey':
      command => "certtool --generate-privkey --bits 2048 --outfile ${strongswan::cert_dir}/private/${::fqdn}.pem",
      creates => "${strongswan::cert_dir}/private/${::fqdn}.pem";
  } -> exec{'ipsec_monkeysphere_cert':
      command => "monkeysphere-host import-key ${strongswan::cert_dir}/private/${::fqdn}.pem ike://${::fqdn} && gpg --homedir /var/lib/monkeysphere/host -a --export =ike://${::fqdn} > ${strongswan::cert_dir}/certs/${::fqdn}.asc",
      creates => "${strongswan::cert_dir}/certs/${::fqdn}.asc",
  } -> anchor{'strongswan::certs::done': }

  File {
    require => Package['strongswan'],
    notify  => Service['ipsec'],
    owner   => root,
    group   => 0,
    mode    => 0400,
  }

  $binary_name = basename($strongswan::binary)
  file{
    '/etc/ipsec.secrets':
      content => ": RSA ${::fqdn}.pem\n";
      
    # this is needed because if the glob-include in the config
    # doesn't find anything it fails.
    "${strongswan::config_dir}/hosts":
      ensure  => directory,
      purge   => true,
      force   => true,
      recurse => true;

    '/etc/ipsec.conf':
      content => template('strongswan/ipsec.conf.erb');

    "/usr/local/sbin/${binary_name}_connected_hosts":
      content => "#!/bin/bash\n${strongswan::binary} status | grep INSTALLED | awk -F\\{ '{ print \$1 }'\n",
      notify  => undef,
      mode    => 0500;

    "/usr/local/sbin/${binary_name}_info":
      content => template('strongswan/scripts/info.sh.erb'),
      notify  => undef,
      mode    => 0500;

    "/usr/local/sbin/${binary_name}_start_unconnected":
      content => template('strongswan/scripts/start_unconnected.sh.erb'),
      notify  => undef,
      mode    => 0500;
  }
  concat{'strongswan_puppet_managed_hosts':
    path    => "${strongswan::config_dir}/hosts/puppet_managed.conf",
    require => Package['strongswan'],
    notify  => Service['ipsec'],
    owner   => root,
    group   => 0,
    mode    => 0400;
  }

  service{'ipsec':
    ensure => running,
    enable => true,
  }
}
