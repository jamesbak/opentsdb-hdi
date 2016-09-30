#!/usr/bin/env python

import sys, os, pwd, signal, time
from resource_management import *

class TSDProxy(Script):
  def install(self, env):
    # Install packages listed in metainfo.xml
    self.install_packages(env)
    import params

    Logger.info("TSDProxy - Starting installation.")
    Execute('wget https://repo.varnish-cache.org/pkg/5.0.0/varnish_5.0.0-1_amd64.deb -O /tmp/varnish_5.0.0-1_amd64.deb')
    Execute('dpkg -i /tmp/varnish_5.0.0-1_amd64.deb')
    # Installation starts the service - stop it now
    Execute('service varnish stop')
    Logger.info("TSDProxy - Installation complete.")

  def configure(self, env):
    import params
    env.set_params(params)

    Logger.info("TSDProxy - Starting configuration.")
    File("/etc/varnish/default.vcl",
         content = Template("default.vcl.j2"))
    File("/etc/default/varnish",
         content = StaticFile("varnish"),
         mode = 0644)
    Logger.info("TSDProxy - Configuration completed.")

  def start(self, env):
    import params
    self.configure(env)

    Logger.info("TSDProxy - Starting service.")
    Execute('service varnish start')
    Logger.info("TSDProxy - Service is running.")

  def stop(self, env):
    Logger.info("TSDProxy - Stopping service.")
    Execute('service varnish stop')
    Logger.info("TSDProxy - Service is stopped.")

  def status(self, env):
    check_process_status('/var/run/varnishd.pid')

if __name__ == "__main__":
  TSDProxy().execute()


