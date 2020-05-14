# @summary Manages the auto-restart (aka service recovery) for a Windows service.
#
#
# @param [Enum['noop', 'reboot', 'restart', 'run_command']] action
#   - 'noop' = take no action.
#   - 'reboot' = reboot the computer, displaying `reboot_message` before rebooting.
#   - 'restart' = restart the service.
#   - `run_command` = executes the `command`  when the service fails
#
# @param [Integer[0]] delay
#   Number of millisecondsseconds (positive number) to wait before restarting the service.
#
# @param [Integer[0]] reset_period
#   Number of seconds to wait before resetting the "failed" count. Default: 86,400 = 1 day (Windows default).
#
# @param [Optional[String]] reboot_message
#   Message to display before rebooting the computer. This is only used when specifying
#   `action => 'reboot'`
#
# @param [Optional[String]] command
#   Command to run on failure. This is only used when specifying an `action => 'command'.
#
# @example Auto-restart the Puppet service
#   service_autorestart::windows { 'puppet': }
#
# @example Delay restarting the service for 60 seconds.
#   service_autorestart::windows { 'puppet':
#     delay => 60000,  # delay is in milliseconds
#   }
#
# @example Reboot the computer when the service fails
#   service_autorestart::windows { 'myservice':
#     action         => 'reboot',
#     reboot_message => 'service "myservice" failed, rebooting',
#   }
#
# @example Run a command when the service fails
#   service_autorestart::windows { 'myservice':
#     action  => 'run_command',
#     command => 'msg "myservice failed, showing a popup so you know"',
#   }
#
define service_autorestart::windows (
  Enum['noop', 'reboot', 'restart', 'run_command'] $action = 'restart',
  Integer[0] $delay                = 1000,
  Integer[0] $reset_period         = 86400,
  Optional[String] $reboot_message = undef,
  Optional[String] $command        = undef,
) {
  service_recovery { $title:
    reset_period    => $reset_period,
    reboot_message  => $reboot_message,
    command         => $command,
    failure_actions => [
      {
        action => $action,
        delay  => $delay,
      },
      {
        action => $action,
        delay  => $delay,
      },
      {
        action => $action,
        delay  => $delay,
      },
    ],
  }
}
