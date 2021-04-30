# Changelog

All notable changes to this project will be documented in this file.

## Release 0.1.4

**Bugfixes**

* Fixed `data/common.yaml` to contain a valid hash, fixing Puppet Server side warnings.

## Release 0.1.3

**Features**

* PDK update to `1.18.0`

## Release 0.1.2

**Bugfixes**

* Fixed `service_autorestart::systemd` from throwing and error on Ubuntu because it was using a different
  path for `.service` files. We now use module-level hiera data to default these locations.

## Release 0.1.1

**Bugfixes**

* Change from using `$facts['os']['family']` to `$facts['service_provider']` from `puppetlabs/stdlib`.
  This allows `service_autorestart::generic` to "do the right thing" when detecting systemd.

## Release 0.1.0

**Features**

Initial implemention including the following types:
* `service_autorestart::generic` - Single type to define a basic `service_autorestart::xxx` resource 
     depending on what OS is in `$facts`
* `service_autorestart::systemd` - Resource to manage autorestart capability on SystemD OSes.
* `service_autorestart::windows` - Resource to manage autorestart capability on Windows.
* `service_recovery`  - Resource to manage low-level configuration of Service Recovery on Windows.

**Bugfixes**

**Known Issues**
