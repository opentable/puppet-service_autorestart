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
# @param [Boolean] autonotify_path
#   Flag to enable creating an automatic notify relationship between the File[$path]
#   and the Ini settings to modify the Restart parameters.
#   Even if enabled, the relationships are protected with a guard, so if File[$path] is not
#   defined the relationship will not be created. This prevents errors in environments where
#   these resources aren't managed by Puppet
#
# @param [Boolean] autonotify_systemctl_daemon_reload
#   Flag to enable creating an automatic notify relationship between the 'systemctl daemon-reload'
#   command and the Ini settings to modify the Restart parameters.
#   The settings will be applied first and the notify the Class['systemd::systemctl::daemon_reload']
#   of changes.
#   This is enabled by default but probably only useful if you use the camptocamp/systemd module.
#   Even if enabled, the relationships are protected with a guard, so if
#   Class['systemd::systemctl::daemon_reload'] is not defined the relationship will not
#   be created. This prevents errors in environments where these resources aren't managed by
#   Puppet or the camptocamp/systemd module is not used.
#
# @example Basic usage
#   service_autorestart::systemd { 'puppet': }
#
# @example Customize the delay between restarts
#   service_autorestart::systemd { 'puppet':
#     delay => '90s',
#   }
#
# @example Customize the path and when action restarts
#   service_autorestart::systemd { 'puppet':
#     path  => '/usr/local/lib/systemd/system/puppet.service',
#     value => 'on-abort',
#     delay => '90s',
#   }
#
# @example Disable auto-notify relationships
#   service_autorestart::systemd { 'puppet':
#     autonotify_path                    => false,
#     autonotify_systemctl_daemon_reload => false,
#   }
#
define service_autorestart::systemd (
  String $path  = "/usr/lib/systemd/system/${title}.service",
  String $value = 'on-failure',
  Optional[String] $delay = undef,
  Boolean $autonotify_path = true,
  Boolean $autonotify_systemctl_daemon_reload = true
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

  # make sure the file exists before we modify it
  if $autonotify_path and defined(File[$path]) {
    File[$path] ~> Ini_setting<| tag == 'service_autorestart' |>
  }

  # if we're using the camptocamp/systemd module, invoke systemctl daemon_reload
  # so systemd knows about our file changes
  if $autonotify_systemctl_daemon_reload and defined(Class['systemd::systemctl::daemon_reload']) {
    Ini_setting<| tag == 'service_autorestart' |> ~> Class['systemd::systemctl::daemon_reload']
  }
}
