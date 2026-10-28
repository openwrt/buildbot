This test checks that signall.sh produces apk indexes that the apk on OpenWrt
main and 25.12 devices accepts, and that signing is deterministic.

The key, package and index are generated inside a container from the master
image, which has the openssl, apk and signall.sh that releases use. The runner
needs only docker, and only the final verification runs on the host.

Start a separate container from the master image for the whole test. The test
needs only the tools in the image, not a running buildmaster, so it does not
depend on the state of test-master. The container removes itself when it
stops, and it stops on its own after ten minutes, so an interrupted run does
not leave it behind.

  $ docker run --rm --detach --name signing-test --entrypoint sleep local/master 600 > /dev/null

Copy the helper into the container and create the test fixtures: a P-256 key
pair, a tiny package, an index of it and a tarball like the ones phase1 and
phase2 upload.

  $ docker cp "$TESTDIR/signing-fixtures.sh" signing-test:/signing-fixtures.sh
  $ docker exec signing-test /signing-fixtures.sh create /tmp/signing

Sign two fresh copies of the same unsigned tarball with signall.sh, the way a
release does.

  $ docker exec signing-test /signing-fixtures.sh sign /tmp/signing first_run
  $ docker exec signing-test /signing-fixtures.sh sign /tmp/signing second_run

The signed index must carry a valid signature, checked with the buildmaster
apk itself. Without this check, a signall.sh run that silently skipped signing
would give two identical unsigned files and pass the determinism check below.

  $ docker exec signing-test apk verify --keys-dir /tmp/signing/public_keys /tmp/signing/first_run/packages.adb
  /tmp/signing/first_run/packages.adb: OK

Signing must be deterministic. Without the deterministic ECDSA patch in the
buildmaster apk, each signature would differ and the two files would not be
identical.

  $ docker exec signing-test cmp /tmp/signing/first_run/packages.adb /tmp/signing/second_run/packages.adb && echo identical
  identical

The sha256sums file of the tarball must describe the signed index, not the
unsigned one.

  $ docker exec --workdir /tmp/signing/first_run signing-test sha256sum --check --quiet sha256sums && echo checksums match
  checksums match

Make a copy of the signed index with one payload byte changed, for the
negative control further down. Confirm that it really differs.

  $ docker exec signing-test /signing-fixtures.sh tamper /tmp/signing
  $ docker exec signing-test cmp -s /tmp/signing/first_run/packages.adb /tmp/signing/tampered/packages.adb \
  >   || echo "tampered index differs from the signed one"
  tampered index differs from the signed one

Copy the public key and both indexes out of the container. The private key
stays inside.

  $ mkdir "$CRAMTMP/verify"
  $ docker cp signing-test:/tmp/signing/public_keys "$CRAMTMP/verify/public_keys"
  $ docker cp signing-test:/tmp/signing/first_run/packages.adb "$CRAMTMP/verify/packages.adb"
  $ docker cp signing-test:/tmp/signing/tampered/packages.adb "$CRAMTMP/verify/tampered.adb"

Pull the device images first. Docker prints pull progress on stderr, which
would otherwise end up in the test output on a runner without cached images.

  $ for image_tag in x86-64-main x86-64-openwrt-25.12 x86-64-25.12.6; do
  >   docker pull --quiet "ghcr.io/openwrt/rootfs:$image_tag" > /dev/null \
  >     && echo "$image_tag pulled"
  > done
  x86-64-main pulled
  x86-64-openwrt-25.12 pulled
  x86-64-25.12.6 pulled

Verify the signed index with the apk shipped on devices: OpenWrt main, the
25.12 branch and one pinned 25.12 release. The pinned release shows which side
changed when only the moving tags fail.

  $ for image_tag in x86-64-main x86-64-openwrt-25.12 x86-64-25.12.6; do
  >   docker run --rm -v "$CRAMTMP/verify:/verify:ro" "ghcr.io/openwrt/rootfs:$image_tag" \
  >     apk verify --keys-dir /verify/public_keys /verify/packages.adb > /dev/null \
  >     && echo "$image_tag OK"
  > done
  x86-64-main OK
  x86-64-openwrt-25.12 OK
  x86-64-25.12.6 OK

Negative control: the index with the changed payload byte must fail
verification, and the reason must be its signature. This catches a verifier
that accepts everything.

  $ docker run --rm -v "$CRAMTMP/verify:/verify:ro" ghcr.io/openwrt/rootfs:x86-64-main \
  >   apk verify --keys-dir /verify/public_keys /verify/tampered.adb \
  >   > "$CRAMTMP/tampered-verify.log" 2>&1 \
  >   || echo "tampered index rejected"
  tampered index rejected
  $ grep -o 'UNTRUSTED signature' "$CRAMTMP/tampered-verify.log"
  UNTRUSTED signature

Remove the container and everything in it.

  $ docker rm --force --volumes signing-test > /dev/null
