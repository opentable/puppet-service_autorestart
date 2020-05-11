require 'puppet/resource_api/simple_provider'
require 'ruby-pwsh'

# class to provide service recovery for windows
class Puppet::Provider::ServiceRecovery::ServiceRecovery < Puppet::ResourceApi::SimpleProvider
  # def initialize
  #   # in normal types/providers this would be:
  #   #   commands powershell: 'powershell.exe'
  #   @powershell = Puppet::Provider::Command.new(name,
  #                                               path,
  #                                               Puppet::Util, Puppet::Util::Execution,
  #                                               { :failonfail => true,
  #                                                 :combine => true,
  #                                                 :custom_environment => {} })
  # end

  def powershell
    return @powershell if @powershell
    debug_output = Puppet::Util::Log.level == :debug
    # TODO: Allow you to specify an alternate path, either to pwsh generally or a specific pwsh path.
    @powershell = Pwsh::Manager.instance(Pwsh::Manager.powershell_path,
                                         Pwsh::Manager.powershell_args,
                                         debug: debug_output)
  end

  def get(context)
    # first ask sc for a list of services
    query = powershell.execute('sc.exe query')[:stdout]
    services = query.lines.each_with_object([]) do |line, memo|
      # skip lines that aren't names of services
      # format:
      #  SERVICE_NAME: <service_name>\r\n
      if match = line.match(%r{SERVICE_NAME: (.*)\s*})
        service_name = match.captures[0]
        memo << service_name
      end
    end

    # for each service, ask sc for information on its service recovery (aka failure)
    # configuration
    services.map do |service_name|
      qfailure = powershell.execute("sc.exe qfailure #{service_name}")[:stdout]
      # TODO: document the idempotency of specifying "noop" for failure actions
      #   - FYI it will result in loss of idempotency because the sc out put doesn't
      #     give us a "noop" placeholder
      recovery = qfailure.lines.each_with_object({}) do |line, memo|
        if match = line.match(%r{\s*RESET_PERIOD (in seconds)    : (.*)\s*})
          memo[:reset_period] = match.captures[0]
        elsif match = line.match(%r{\s*REBOOT_MESSAGE               : (.*)\s*})
          memo[:reboot_message] = match.captures[0]
        elsif match = line.match(%r{\s*COMMAND_LINE                 : (.*)\s*})
          memo[:command] = match.captures[0]
        elsif match = line.match(%r{.*RESTART -- Delay = (\d+) milliseconds.\s*})
          delay_ms = match.captures[0]
          failure_actions = memo.fetch(:failure_actions, [])
          failure_actions << {
            action: 'restart',
            delay: delay_ms,
          }
        elsif match = line.match(%r{.*RUN PROCESS -- Delay = (\d+) milliseconds.\s*})
          delay_ms = match.captures[0]
          failure_actions = memo.fetch(:failure_actions, [])
          failure_actions << {
            action: 'run_command',
            delay: delay_ms,
          }
        elsif match = line.match(%r{.*REBOOT -- Delay = (\d+) milliseconds.\s*})
          delay_ms = match.captures[0]
          failure_actions = memo.fetch(:failure_actions, [])
          failure_actions << {
            action: 'reboot',
            delay: delay_ms,
          }
        end
      end
      recovery[:name] = service_name
      recovery[:ensure] = 'present'
    end
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
end
o
