# @summary Configures a service for auto-restart in a platform agnostic way.
#
# This is very simplistic and doesn't allow tweaking of the parmeters. If you need
# to tweak settings,  you'll need to declare the `service_autorestart::windows`
# or `service_autorestart::systemd` directly.
define service_autorestart::generic () {
  case $facts['service_provider'] {
    'windows': {
      service_autorestart::windows { $title: }
    }
    'systemd': {
      service_autorestart::systemd { $title: }
    }
    default: {}
  }
}
