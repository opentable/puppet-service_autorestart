Puppet::ResourceApi.register_type(
  name: 'service_recovery',
  desc: <<-EOS,
    Manages the Recovery/Failure settings for a Windows Service

    **Autorequires**:
    Puppet will auto-require the service resource with the same 'name' as this resource.
  EOS
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this apt key should be present or absent on the target system.',
    },
    name: {
      type:      'String[1]',
      behaviour: :namevar,
      desc:      'Name of the service.',
    },
    reset_period: {
      type: 'Integer[0]',
      desc: 'Number of seconds to wait before resetting the "failed" count. Default: 8640 = 1 day (Windows default).',
      default: 8640,
    },
    reboot_message: {
      type: 'String',
      desc: 'Message to display before rebooting the computer. This only matters if you use a "failure_action" with an "action" of "reboot".',
    },
    command: {
      type: 'String',
      desc: 'Command to run on failure. This only matters if you use a "failure_action" with an "action" of "run_command". Note: Windows uses the same command for each failure, you can not specify a unique command per-failure.',
    },
    failure_actions: {
      type: 'Array[Struct[{action => Enum["noop", "reboot", "restart", "run_command"], delay => Integer[0]} ] ]',
      desc: 'List of actions to perform when the service fails. This takes two parameters "action", the type of action to execute. Action "noop" means take no action. Action "reboot" means reboot the computer display the "reboot_message" prior to rebooting. Action "restart" means restart the service. Action "run_command" executes the "command" when the service fails. The "delay" parameter is measure in milliseconds.',
    },
  },
  autorequire: {
    service: '$name', # evaluates to the value of the `name` attribute
  },
)
