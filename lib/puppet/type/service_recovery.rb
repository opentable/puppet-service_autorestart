Puppet::Type.newtype(:service_recovery) do
  desc 'Manages the Recovery/Failure settings for a Windows Service'

  newparam(:name, namevar: true) do
    desc 'The name of the service'
  end

  newparam(:reset_period) do
    desc 'Number of seconds to wait before resetting the "failed" count. Default: 86,400 = 1 day (Windows default).'
    defaultto do
      86_400
    end
    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "reset_period must be an integer: #{value} [#{value.class.name}]"
      end
    end
  end

  newparam(:reboot_message) do
    desc 'Number of seconds to wait before resetting the "failed" count. Default: 86,400 = 1 day (Windows default).'
    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "reboot_message must be an string: #{value} [#{value.class.name}]"
      end
    end
  end

  newparam(:command) do
    desc <<-EOS
        Command to run on failure. This only matters if you use a "failure_action" with an
        "action" of "run_command". Note: Windows uses the same command for each failure,
        you can not specify a unique command per-failure.'
    EOS
    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "command must be an string: #{value} [#{value.class.name}]"
      end
    end
  end

  newparam(:failure_actions) do
    desc <<-EOS
        List of actions to perform when the service fails. This takes two parameters "action",
        the type of action to execute. Action "noop" means take no action. Action "reboot"
        means reboot the computer display the "reboot_message" prior to rebooting. Action
        "restart" means restart the service. Action "run_command" executes the "command"
        when the service fails. The "delay" parameter is measure in milliseconds. The maximum
        size of this array is 3.'
    EOS
    # munge to set default delay to 1 second (1,000ms)
    munge do |value|
      return value unless value.is_a?(Array)
      value.each do |v|
        next unless v.is_a?(Hash)
        next unless v['delay']
        v['delay'] = 1_000
      end
      value
    end

    # validate failure actions array of hashes
    validate do |value|
      value = munge(value)
      unless value.is_a?(Array)
        raise ArgumentError, "failure_actions must be an array: #{value} [#{value.class.name}]"
      end
      unless value.size <= 3
        raise ArgumentError, "failure_actions array can contain at most 3 elements, you passed in : #{value.size}"
      end
      value.each do |v|
        unless v.is_a?(Hash)
          raise ArgumentError, "failure_actions array elements must be hashes: #{v} [#{v.class.name}]"
        end
        # validate the 'action' parameter
        unless v.key?('action')
          raise ArgumentError, "failure_actions hash must contain an 'action' key: #{v} [#{v.class.name}]"
        end
        unless ['noop', 'reboot', 'restart', 'run_command'].include?(v['action'])
          raise ArgumentError, "failure_actions hash's 'action' key must be one of ('noop', 'reboot', 'restart', 'run_command'. You passed in: #{v['action']} [#{v['action'].class.name}]"
        end

        # validate the 'delay' parameter
        unless v.key?('delay')
          raise ArgumentError, "failure_actions hash must contain a 'delay' key: #{v} [#{v.class.name}]"
        end
        unless v > 0
          raise ArgumentError, "failure_actions hash's 'delay' value must be positive: #{v['delay']} [#{v['delay'].class.name}]"
        end
      end
    end
  end

  # Autorequire the service with the same name
  autorequire(:service) do
    self[:name]
  end
end

########################
# old

# require 'puppet/resource_api'

# Puppet::ResourceApi.register_type(
#   name: 'service_recovery',
#   desc: <<-EOS,
#     Manages the Recovery/Failure settings for a Windows Service

#     **Autorequires**:
#     Puppet will auto-require the service resource with the same 'name' as this resource.
#   EOS
#   attributes: {
#     ensure: {
#       type: 'Enum[present, absent]',
#       desc: 'Whether this apt key should be present or absent on the target system.',
#     },
#     name: {
#       type:      'String[1]',
#       behaviour: :namevar,
#       desc:      'Name of the service.',
#     },
#     reset_period: {
#       type: 'Integer[0]',
#       desc: 'Number of seconds to wait before resetting the "failed" count. Default: 86,400 = 1 day (Windows default).',
#       default: 86_400,
#     },
#     reboot_message: {
#       type: 'Optional[String]',
#       desc: 'Message to display before rebooting the computer. This only matters if you use a "failure_action" with an "action" of "reboot".',
#     },
#     command: {
#       type: 'Optional[String]',
#       desc: <<-EOS,
#         Command to run on failure. This only matters if you use a "failure_action" with an
#         "action" of "run_command". Note: Windows uses the same command for each failure,
#         you can not specify a unique command per-failure.'
#       EOS
#     },
#     failure_actions: {
#       type: 'Array[Struct[{action => Enum["noop", "reboot", "restart", "run_command"], delay => Integer[0]} ], 0, 3]',
#       desc: <<-EOS,
#         List of actions to perform when the service fails. This takes two parameters "action",
#         the type of action to execute. Action "noop" means take no action. Action "reboot"
#         means reboot the computer display the "reboot_message" prior to rebooting. Action
#         "restart" means restart the service. Action "run_command" executes the "command"
#         when the service fails. The "delay" parameter is measure in milliseconds. The maximum
#         size of this array is 3.'
#       EOS
#       default: [],
#     },
#   },
#   autorequire: {
#     service: '$name', # evaluates to the value of the `name` attribute
#   },
# )
