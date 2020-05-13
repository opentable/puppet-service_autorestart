Puppet::Type.type(:service_recovery).provide(:service_recovery) do
  desc 'Provides support for managing st2 packs'

  commands sc: 'sc.exe'

  def initialize(value = {})
    super(value)
    @property_flush = {}
    @regex_reset_period = Regexp.new(%r{\s*RESET_PERIOD (in seconds)    : (.*)\s*})
    @regex_reboot_message = Regexp.new(%r{\s*REBOOT_MESSAGE               : (.*)\s*})
    @regex_command_line = Regexp.new(%r{\s*COMMAND_LINE                 : (.*)\s*})
    @regex_restart = Regexp.new(%r{.*RESTART -- Delay = (\d+) milliseconds.\s*})
    @regex_run_process = Regexp.new(%r{.*RUN PROCESS -- Delay = (\d+) milliseconds.\s*})
    @regex_reboot = Regexp.new(%r{.*REBOOT -- Delay = (\d+) milliseconds.\s*})
  end

  ######################
  # public methods used by the type/provider system in Puppet
  def reset_period
    service_recovery_instance[:reset_period]
  end

  def reset_period=(value)
    @property_flush[:reset_period] = value
  end

  def reboot_message
    service_recovery_instance[:reboot_message]
  end

  def reboot_message=(value)
    @property_flush[:reboot_message] = value
  end

  def command
    service_recovery_instance[:command]
  end

  def command=(value)
    @property_flush[:command] = value
  end

  def failure_actions
    service_recovery_instance[:failure_actions]
  end

  def failure_actions=(value)
    @property_flush[:failure_actions] = value
  end

  # do one big "set" all at once for all the properties
  def flush
    return unless @property_flush

    arguments = ['failure', @resource[:name]]
    if @property_flush[:reset_period]
      arguments << ('reset=' + @property_flush[:reset_period])
    end
    if @property_flush[:reset_period]
      arguments << ('reboot="' + @property_flush[:reset_period] + '"')
    end
    if @property_flush[:command]
      arguments << ('command="' + @property_flush[:command] + '"')
    end
    if @property_flush[:failure_actions]
      actions_arg = 'actions='
      @property_flush[:failure_actions].each do |fa|
        action = case fa[:action]
                 when 'noop'
                   ''
                 when 'restart'
                   'restart'
                 when 'reboot'
                   'reboot'
                 when 'run_command'
                   'run'
                 end
        delay = fa[:delay]
        actions_arg += "#{action}/#{delay}/"
      end
      arguments << actions_arg
    end
    sc(arguments)
  end

  ######################
  # private methods
  def service_recovery_instance(service)
    return @service if @service
    # ask sc about failure/recovery information for this service
    qfailure = sc('qfailure', @resource[:name])
    if qfailure.include?('[SC] OpenService FAILED')
      @service = nil
      return @service
    end

    # TODO: document the idempotency of specifying "noop" for failure actions
    #   - FYI it will result in loss of idempotency because the sc out put doesn't
    #     give us a "noop" placeholder
    recovery = {
      name: service,
      failure_actions: [],
    }
    @service = qfailure.lines.each_with_object(recovery) do |line, memo|
      if !memo.key?(:reset_period) && (match = @regex_reset_period.match(line))
        memo[:reset_period] = match.captures[0]
      elsif !memo.key?(:reboot_message) && (match = @regex_reboot_message.match(line))
        memo[:reboot_message] = match.captures[0]
      elsif !memo.key?(:command) && (match = @regex_command_line.match(line))
        memo[:command] = match.captures[0]
      elsif (match = @regex_restart.match(line))
        delay_ms = match.captures[0].to_i
        memo[:failure_actions] << {
          action: 'restart',
          delay: delay_ms,
        }
      elsif (match = @regex_run_process.match(line))
        delay_ms = match.captures[0].to_i
        memo[:failure_actions] << {
          action: 'run_command',
          delay: delay_ms,
        }
      elsif (match = @regex_reboot.match(line))
        delay_ms = match.captures[0].to_i
        memo[:failure_actions] << {
          action: 'reboot',
          delay: delay_ms,
        }
      end
    end
    @service
  end
end

############################
# old

# require 'puppet/resource_api/simple_provider'

# # class to provide service recovery for windows
# class Puppet::Provider::ServiceRecovery::ServiceRecovery < Puppet::ResourceApi::SimpleProvider
#   def initialize
#     @regex_reset_period = Regexp.new(%r{\s*RESET_PERIOD (in seconds)    : (.*)\s*})
#     @regex_reboot_message = Regexp.new(%r{\s*REBOOT_MESSAGE               : (.*)\s*})
#     @regex_command_line = Regexp.new(%r{\s*COMMAND_LINE                 : (.*)\s*})
#     @regex_restart = Regexp.new(%r{.*RESTART -- Delay = (\d+) milliseconds.\s*})
#     @regex_run_process = Regexp.new(%r{.*RUN PROCESS -- Delay = (\d+) milliseconds.\s*})
#     @regex_reboot = Regexp.new(%r{.*REBOOT -- Delay = (\d+) milliseconds.\s*})
#   end

#   #######################
#   # public methods inherited from Resource API
#   def get(context)
#     # first get a list of services from sc
#     services = services_list(context)

#     # for each service, ask sc for information on its service recovery (aka failure)
#     # configuration
#     services.map { |service_name| service_recovery_instance(context, service_name) }
#   end

#   def create(context, name, should)
#     context.info("service_recover[#{name}] = create ... #{should}")
#   end

#   def update(context, name, should)
#     context.info("service_recover[#{name}] = update ... #{should}")
#   end

#   def delete(context, name)
#     context.info("service_recover[#{name}] = delete")
#   end

#   #######################
#   # private method
#   def sc(*args)
#     unless @sc
#       @sc = Puppet::Provider::Command.new('sc',
#                                           'sc.exe',
#                                           Puppet::Util,
#                                           Puppet::Util::Execution,
#                                           failonfail: true,
#                                           combine: true,
#                                           custom_environment: {})
#     end
#     @sc.execute(*args)
#   end

#   def services_list(_context)
#     return @services_list if @services_list
#     query = sc('query')
#     @services_list = query.lines.each_with_object([]) do |line, memo|
#       # skip lines that aren't names of services
#       # format:
#       #  SERVICE_NAME: <service_name>\r\n
#       if (match = line.match(%r{SERVICE_NAME: (.*)\s*}))
#         service_name = match.captures[0]
#         memo << service_name.strip
#       end
#     end
#   end

#   def service_recovery_instance(_context, service)
#     # ask sc about failure/recovery information for this service
#     qfailure = sc('qfailure', service)

#     # TODO: document the idempotency of specifying "noop" for failure actions
#     #   - FYI it will result in loss of idempotency because the sc out put doesn't
#     #     give us a "noop" placeholder
#     recovery = {
#       name: service,
#       ensure: 'present',
#       failure_actions: [],
#     }
#     qfailure.lines.each_with_object(recovery) do |line, memo|
#       if !memo.key?(:reset_period) && (match = @regex_reset_period.match(line))
#         memo[:reset_period] = match.captures[0]
#       elsif !memo.key?(:reboot_message) && (match = @regex_reboot_message.match(line))
#         memo[:reboot_message] = match.captures[0]
#       elsif !memo.key?(:command) && (match = @regex_command_line.match(line))
#         memo[:command] = match.captures[0]
#       elsif (match = @regex_restart.match(line))
#         delay_ms = match.captures[0].to_i
#         memo[:failure_actions] << {
#           action: 'restart',
#           delay: delay_ms,
#         }
#       elsif (match = @regex_run_process.match(line))
#         delay_ms = match.captures[0].to_i
#         memo[:failure_actions] << {
#           action: 'run_command',
#           delay: delay_ms,
#         }
#       elsif (match = @regex_reboot.match(line))
#         delay_ms = match.captures[0].to_i
#         memo[:failure_actions] << {
#           action: 'reboot',
#           delay: delay_ms,
#         }
#       end
#     end

# #       # processing like this is faster than processing via
# #       line_parts = line.split(': ')
# #       processed = false
# #       case line_parts[0]
# #       when '        RESET_PERIOD (in seconds)    '
# #         memo[:reset_period] = line_parts[1].strip.to_i
# #         processed = true
# #       when '        REBOOT_MESSAGE               '
# #         memo[:reboot_message] = line_parts[1].strip
# #         processed = true
# #       when '        COMMAND_LINE                 '
# #         memo[:command] = line_parts[1].strip
# #         processed = true
# #       when '        FAILURE_ACTIONS              '
# #         line = line_parts[1]
# #       end
# #       next if processed

# # #        FAILURE_ACTIONS              : RESTART -- Delay = 60000 milliseconds.
# # #                                       RUN PROCESS -- Delay = 0 milliseconds.
# # #                                       REBOOT -- Delay = 60000 milliseconds.
# #       line_parts = line.split(' -- Delay = ')
# #       next if line_parts.size < 2

# #       action = case line_parts[0]
# #                when 'RESTART'
# #                  'restart'
# #                when 'RUN PROCESS'
# #                  'run_command'
# #                when 'REBOOT'
# #                  'reboot'
# #                end
# #       delay_ms = line_parts[1].gsub(' milliseconds.', '').strip.to_i
# #       failure_actions = memo.fetch(:failure_actions, [])
# #       failure_actions << {
# #         action: action,
# #         delay: delay_ms,
# #       }
# #     end
#   end
# end
