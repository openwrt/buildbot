Check that apk is available and usable in master container:

  $ docker run --entrypoint apk local/master | grep usage
  usage: apk [<OPTIONS>...] COMMAND [<ARGUMENTS>...]
