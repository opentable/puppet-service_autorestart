# @summary Manages the auto-restart (aka service recovery) for a SystemD service.
#
# @param [String] path
#   Path to the systemd service file for this service
#
# @param [String] value
#   The value of the `Reset=` setting for the SystemD service.
#   https://www.freedesktop.org/software/systemd/man/systemd.service.html#Restart=
#
# @param [String] delay
#   The value of the `ResetSec=` setting for the SystemD service.
#   https://www.freedesktop.org/software/systemd/man/systemd.service.html#RestartSec=
#
# @example Basic usage
#   service_autorestart::systemd { 'puppet':
#     path => '/usr/lib/systemd/system/puppet.service',
#   }
#
# @example Customize the delay between restarts
#   service_autorestart::systemd { 'puppet':
#     path  => '/usr/lib/systemd/system/puppet.service',
#     delay => '90s',
#   }
#
# @example Customize when the action restarts
#   service_autorestart::systemd { 'puppet':
#     path  => '/usr/lib/systemd/system/puppet.service',
#     value => 'on-abort',
#     delay => '90s',
#   }
#
define service_autorestart::systemd (
  String $path  = "/usr/lib/systemd/system/${title}.service",
  String $value = 'on-failure',
  Optional[String] $delay = undef,
  Optional[String] $autorequire_service = $title,
) {
  ini_setting { "systemd_${title}_restart":
    ensure            => present,
    path              => $path,
    section           => 'Service',
    setting           => 'Restart',
    value             => $value,
    key_val_separator => '=',
    tag               => 'service_autorestart',
  }

  if $delay {
    ini_setting { "systemd_${title}_restartsec":
      ensure            => present,
      path              => $path,
      section           => 'Service',
      setting           => 'RestartSec',
      value             => $delay,
      key_val_separator => '=',
      tag               => 'service_autorestart',
    }
  }

  if $autorequire_service {
    Service[$autorequire_service]
    -> Ini_setting<| tag == 'service_autorestart' |>
  }
}
