puppet-strongswan
=================

Puppet module to manage strongswan VPN dealie

## Usage
(Defaults shown)
```puppet
class { 'strongswan':
  manage_shorewall         => false,
  shorewall_source         => 'net',
  monkeysphere_publish_key => false,
  ipsec_nat                => false,
  default_left_ip_address  => $::ipaddress,
  default_left_subnet      => reject(split($::strongswan_ips,','),$::ipaddress),
  additional_options       => '',
  auto_remote_host         => false
}
```