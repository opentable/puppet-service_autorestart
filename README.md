# service_autorestart

[![Build Status](https://travis-ci.org/EncoreTechnologies/puppet-service_autorestart.svg?branch=master)](https://travis-ci.org/EncoreTechnologies/puppet-service_autorestart)
[![Puppet Forge Version](https://img.shields.io/puppetforge/v/encore/service_autorestart.svg)](https://forge.puppet.com/encore/service_autorestart)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/encore/service_autorestart.svg)](https://forge.puppet.com/encore/service_autorestart)
[![Puppet Forge Score](https://img.shields.io/puppetforge/f/encore/service_autorestart.svg)](https://forge.puppet.com/encore/service_autorestart)
[![Puppet PDK Version](https://img.shields.io/puppetforge/pdk-version/encore/service_autorestart.svg)](https://forge.puppet.com/encore/service_autorestart)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/encore-service_autorestart)


#### Table of Contents

1. [Description](#description)
2. [Setup](#setup)
    * [What service_autorestart affects](#what-service_autorestart-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with service_autorestart](#beginning-with-service_autorestart)
3. [Usage](#usage)
    * [Cross-platform autorestart](#cross-platform-autorestart)
    * [SystemD autorestart](#systemd-autorestart)
    * [Windows autorestart](#windows-autorestart)


## Description

This module solves the problem of configuring a service to automatically restart itself
in case the service fails or dies. In Windows this is called "Service Recovery" or
"Service Failure" and can be found in the Service configuration dialog under the "Recovery"
tab. On Linux systems this is simply a parameter on the service unit file in SystemD.

## Setup

### What service_autorestart affects

On Linux, this module changes the SystemD unit file for the service specified, 
adding the `Restart=` and `RestartSec=` parameters.

On Windows, this module configures the Service Recovery (Service Failure) options using
the CLI command `sc.exe`.

### Setup Requirements

This module uses the new [Puppet Resource API](https://puppet.com/docs/puppet/latest/about_the_resource_api.html).

In Puppet `>= 6` the Resource API is included with the agent and server installations.

If you're running Puppet `<= 5` then you'll need to install the Resource API using
the [`puppetlabs/resource_api`](https://forge.puppet.com/puppetlabs/resource_api) module
on the forge.


### Beginning with service_autorestart

Basic usage to enable automatic restarts of a service in a cross-plaform way (works for 
SystemD and Windows):
```puppet
service_autorestart::generic { 'myservice': }
```

This will declare the appropriate resources to configure service autorestart depending on
your OS. It will also automatically declare the correct notify and require relationships
depending on the OS so that things happen in the right order. Example: on Windows the `service`
resource must exist. On Linux the SystemD unit file must exist and we must then invoke
`systemctl daemon-reload` after making our change (requires the use of `camptocamp/sytemd` module
by default).

## Usage

### Cross-platform autorestart

The `service_autorestart::generic` resource provides basic configuration for enabling the
automatic restart capability of a service when it fails. It is intentionally limited on
options. If you need to tweak settings, please declare one of the OS specific resources.

```puppet
service_autorestart::generic { 'myservice': }
```

### SystemD autorestart

Basic usage, configure auto-restart for the Puppet service
```puppet
service_autorestart::systemd { 'puppet': }
```

Customize the delay between restarts
```puppet
service_autorestart::systemd { 'myservice':
  delay => '90s',
}
```

Customize the path and when action restarts
```puppet
service_autorestart::systemd { nginx':
  path  => '/usr/local/lib/systemd/system/nginx.service',
  value => 'on-abort',
  delay => '90s',
}
```

Disable auto-notify relationships
```puppet
service_autorestart::systemd { 'puppet':
  autonotify_path                    => false,
  autonotify_systemctl_daemon_reload => false,
}
```

### Windows autorestart

Basic usage, auto-restart the Puppet service
```puppet
service_autorestart::windows { 'puppet': }
```

Delay restarting the service for 60 seconds.
```puppet
service_autorestart::windows { 'puppet':
  delay => 60000,  # delay is in milliseconds
}
```

Reboot the computer when the service fails
```puppet
service_autorestart::windows { 'myservice':
  action         => 'reboot',
  reboot_message => 'service "myservice" failed, rebooting',
}
```

Run a command when the service fails
```puppet
service_autorestart::windows { 'myservice':
  action  => 'run_command',
  command => 'msg "myservice failed, showing a popup so you know"',
}
```

### Windows Low-level Service Recovery management

Apart from the high-level defines for Windows auto-restarts, we also provide a resource
`service_recovery` to control all aspects of Windows Service Recovery in a fine-grained way:

```puppet
service_recovery { 'myservice':
  reboot_message  => "Rebooting because 'myservice' failed",
  command         => 'msg "myservice failed, showing a popup so you know"',
  failure_actions => [
    {
      action => 'restart',
      delay  => 60000,
    },
    {
      action => 'reboot',
      delay  => 120000,
    },
    {
      action => 'run_command',
      delay  => 180000,
    },
  ],
}
```

For more details on this resource and the options see [REFERENCE.md](REFERENCE.md).

