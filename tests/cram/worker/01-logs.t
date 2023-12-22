Check that logs have expected content after container startup:

  $ docker logs test-worker
  updating existing installation
  mkdir /builder/info
  Creating info/admin, you need to edit it appropriately.
  Creating info/host, you need to edit it appropriately.
  Not creating info/access_uri - add it if you wish
  Please edit the files in /builder/info appropriately.
  worker configured in /builder
