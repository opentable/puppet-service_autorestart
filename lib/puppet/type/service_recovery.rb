require 'puppet/resource_api'

# Manages the Recovery/Failure settings for a Windows Service
# **Autorequires**:
# Puppet will auto-require the service resource with the same 'name' as this resource.
Puppet::ResourceApi.register_type(
  name: 'service_recovery',
  desc: <<-EOS,
    Manages the Recovery/Failure settings for a Windows Service

    **Autorequires**:
    Puppet will auto-require the service resource with the same 'name' as this resource.
  EOS
  # specify this simple_get_filter so we don't have to query for _all_ instances
  # of the service recovery resources (slow)
  features: ['simple_get_filter', 'supports_noop'],
  attributes: {
    name: {
      type:      'String[1]',
      behaviour: :namevar,
      desc:      'Name of the service.',
    },
    reset_period: {
      type: 'Integer[0]',
      desc: 'Number of seconds to wait before resetting the "failed" count. Default: 86,400 = 1 day (Windows default).',
      default: 86_400,
    },
    reboot_message: {
      type: 'Optional[String]',
      desc: 'Message to display before rebooting the computer. This only matters if you use a "failure_action" with an "action" of "reboot".',
    },
    command: {
      type: 'Optional[String]',
      desc: <<-EOS,
        Command to run on failure. This only matters if you use a "failure_action" with an
        "action" of "run_command". Note: Windows uses the same command for each failure,
        you can not specify a unique command per-failure.'
      EOS
    },
    failure_actions: {
      type: 'Array[Struct[{action => Enum["noop", "reboot", "restart", "run_command"], delay => Integer[0]} ], 0, 3]',
      desc: <<-EOS,
        List of actions to perform when the service fails. This takes two parameters "action",
        the type of action to execute. Action "noop" means take no action. Action "reboot"
        means reboot the computer display the "reboot_message" prior to rebooting. Action
        "restart" means restart the service. Action "run_command" executes the "command"
        when the service fails. The "delay" parameter is measure in milliseconds. The maximum
        size of this array is 3.'
      EOS
      default: [],
    },
  },
  autorequire: {
    service: '$name', # evaluates to the value of the `name` attribute
  },
)
