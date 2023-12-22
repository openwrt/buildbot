Check that logs have expected content after container startup:

  $ docker logs test-master
  updating existing installation
  creating /master/master.cfg.sample
  creating database (sqlite:///state.sqlite)
  buildmaster configured in /master
