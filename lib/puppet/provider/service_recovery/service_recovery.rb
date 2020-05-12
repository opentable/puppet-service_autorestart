require 'puppet/resource_api/simple_provider'

# class to provide service recovery for windows
class Puppet::Provider::ServiceRecovery::ServiceRecovery < Puppet::ResourceApi::SimpleProvider
  REGEX_RESET_PERIOD = Regexp.new(%r{\s*RESET_PERIOD (in seconds)    : (.*)\s*})
  REGEX_REBOOT_MESSAGE = Regexp.new(%r{\s*REBOOT_MESSAGE               : (.*)\s*})
  REGEX_COMMAND_LINE = Regexp.new(%r{\s*COMMAND_LINE                 : (.*)\s*})
  REGEX_RESTART = Regexp.new(%r{.*RESTART -- Delay = (\d+) milliseconds.\s*})
  REGEX_RUN_PROCESS = Regexp.new(%r{.*RUN PROCESS -- Delay = (\d+) milliseconds.\s*})
  REGEX_REBOOT = Regexp.new(%r{.*REBOOT -- Delay = (\d+) milliseconds.\s*})

  #######################
  # public methods inherited from Resource API
  def get(context)
    # first get a list of services from sc
    services = services_list(context)

    # for each service, ask sc for information on its service recovery (aka failure)
    # configuration
    services.map { |service_name| service_recovery_instance(context, service_name) }
  end

  def create(context, name, should)
    context.info("service_recover[#{name}] = create ... #{should}")
  end

  def update(context, name, should)
    context.info("service_recover[#{name}] = update ... #{should}")
  end

  def delete(context, name)
    context.info("service_recover[#{name}] = delete")
  end

  #######################
  # private method
  def sc(*args)
    unless @sc
      @sc = Puppet::Provider::Command.new('sc',
                                          'sc.exe',
                                          Puppet::Util,
                                          Puppet::Util::Execution,
                                          failonfail: true,
                                          combine: true,
                                          custom_environment: {})
    end
    @sc.execute(*args)
  end

  def services_list(_context)
    return @services_list if @services_list
    query = sc('query')
    @services_list = query.lines.each_with_object([]) do |line, memo|
      # skip lines that aren't names of services
      # format:
      #  SERVICE_NAME: <service_name>\r\n
      if (match = line.match(%r{SERVICE_NAME: (.*)\s*}))
        service_name = match.captures[0]
        memo << service_name.strip
      end
    end
  end

  def service_recovery_instance(_context, service)
    # ask sc about failure/recovery information for this service
    qfailure = sc('qfailure', service)

    # TODO: document the idempotency of specifying "noop" for failure actions
    #   - FYI it will result in loss of idempotency because the sc out put doesn't
    #     give us a "noop" placeholder
    recovery = {
      name: service,
      ensure: 'present',
    }
    qfailure.lines.each_with_object(recovery) do |line, memo|
      if (match = REGEX_RESET_PERIOD.match(line))
        memo[:reset_period] = match.captures[0]
      elsif (match = REGEX_REBOOT_MESSAGE.match(line))
        memo[:reboot_message] = match.captures[0]
      elsif (match = REGEX_COMMAND_LINE.match(line))
        memo[:command] = match.captures[0]
      elsif (match = REGEX_RESTART.match(line))
        delay_ms = match.captures[0]
        failure_actions = memo.fetch(:failure_actions, [])
        failure_actions << {
          action: 'restart',
          delay: delay_ms,
        }
      elsif (match = REGEX_RUN_PROCESS.match(line))
        delay_ms = match.captures[0]
        failure_actions = memo.fetch(:failure_actions, [])
        failure_actions << {
          action: 'run_command',
          delay: delay_ms,
        }
      elsif (match = REGEX_REBOOT.match(line))
        delay_ms = match.captures[0]
        failure_actions = memo.fetch(:failure_actions, [])
        failure_actions << {
          action: 'reboot',
          delay: delay_ms,
        }
      end
    end
  end
end
