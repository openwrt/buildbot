Check that apk is available and usable in master container:

  $ docker run --entrypoint apk local/master | grep Usage
  Usage: apk [<GLOBAL OPTIONS>...] COMMAND [<OPTIONS>...] [<ARGUMENTS>...]
