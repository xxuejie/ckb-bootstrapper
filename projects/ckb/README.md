This folder contains scripts used to reproducibly build CKB's source archives and binary releases.

All files / folders that start with an `_` are used internally.

Files that start with `build_source_` denotes tasks that reproducibly build source archives.

Files that start with `build_binary_` denotes tasks that reproducibly build binary releases.

When running natively, one can do:

```bash
$ ./build_source_tarball \
  <path to ckb repository> \
  <output folder> \
  <CKB version>
$ ./build_binary_x86-64_linux_gnu \
  <path to ckb repository> \
  <output folder> \
  <CKB version>
```

However, this would require you to manually install all CKB's dependencies(Rust, clang, gcc, OpenSSL, etc.), and make sure specific version for each dependency is used. This typically can be quite a nightmare, so it is not really recommended.

Or we also provide **runners** that take care of dependencies, 2 runners are provided now:

* `guix`: runner powered by guix, you should have guix 1.4+ installed on a modern Linux distribution(for example, CentOS 7 is unusable, since the kernel is too old, guix cannot start an isolated container on CentOS 7)
* `docker`: we also provide a docker image that runs guix underneath. In this setup you can only have docker installed on your machine. Note that `--privileged` will be used when running docker containers(which is required by guix), make sure you read about the quirks for [this flag](https://docs.docker.com/engine/containers/run/#runtime-privilege-and-linux-capabilities).

With runners, you can do the following commands:

```bash
$ ./runner_guix build_source_tarball \
  <path to ckb repository> \
  <output folder for source archives> \
  <CKB version>
$ ./runner_guix build_binary_x86-64_linux_gnu \
  <path to ckb repository> \
  <output folder for binary releases> \
  <CKB version>
$ ./runner_docker build_source_tarball \
  <path to ckb repository> \
  <output folder for source archives> \
  <CKB version>
$ ./runner_docker build_binary_x86-64_linux_gnu \
  <path to ckb repository> \
  <output folder for binary releases> \
  <CKB version>
```

When completed, you would expect new source archives or binary releases in the specified output folder.

Note that the first run of docker runner can be slow due to building process of docker container image. Later executions will reuse already built docker container image, and will be much faster.

One can also tweak the build process, for example, proxy can be used in certain network environment:

```bash
$ DOCKER_RUN_ARGS="-e ALL_PROXY=<proxy> -e HTTPS_PROXY=<proxy> -e HTTP_PROXY=<proxy>" \
  ./runner_docker build_binary_x86-64_linux_gnu \
  <path to ckb repository> \
  <output folder for binary releases> \
  <CKB version>
```

Or you can tweak guix so it builds all dependencies from source instead of using substitutes:

```bash
$ GUIX_SHELL_ARGS="--no-substitutes" \
  ./runner_docker build_binary_x86-64_linux_gnu \
  <path to ckb repository> \
  <output folder for binary releases> \
  <CKB version>
```
