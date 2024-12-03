;; This "manifest" file can be passed to 'guix package -m' to reproduce
;; the content of your profile.  This is "symbolic": it only specifies
;; package names.  To reproduce the exact same profile, you also need to
;; capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu packages)
             (gnu packages base)
             (gnu packages commencement)
             (gnu packages gcc)
             (gnu packages version-control)
             (guix packages)
             (guix git-download)
             ((guix utils) #:select (substitute-keyword-arguments)))

(define-public glibc-2.31-new-gcc
  (let ((commit "7b27c450c34563a28e634cccb399cd415e71ebfe"))
  (package
    (inherit glibc)
    (version "2.31")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://sourceware.org/git/glibc.git")
                    (commit commit)))
              (file-name (git-file-name "glibc" commit))
              (sha256
                (base32
                  "017qdpr5id7ddb4lpkzj2li1abvw916m3fc6n7nw28z4h5qbv2n0"))))
    (arguments
      (substitute-keyword-arguments (package-arguments glibc)
        ((#:configure-flags flags)
          `(append ,flags
            (list "--disable-werror"
                  "libc_cv_cxx_link_ok=no")))
        ((#:phases phases)
          `(modify-phases ,phases
              (delete 'install-utf8-c-locale)
              (add-before 'configure 'set-etc-rpc-installation-directory
                (lambda* (#:key outputs #:allow-other-keys)
                  ;; Install the rpc data base file under `$out/etc/rpc'.
                  (let ((out (assoc-ref outputs "out")))
                    (substitute* "sunrpc/Makefile"
                      (("^\\$\\(inst_sysconfdir\\)/rpc(.*)$" _ suffix)
                       (string-append out "/etc/rpc" suffix "\n"))
                      (("^install-others =.*$")
                       (string-append "install-others = " out "/etc/rpc\n")))))))))))))

;; FIXME: this does not provide a usable C++ compiler now,
;; we will need tricks like Bitcoin's manifest
(define-public gcc-glibc-2.31
  (make-gcc-libc gcc-12 glibc-2.31-new-gcc))

(define gcc-manifest
  (packages->manifest
    (list gcc-glibc-2.31
          glibc-2.31-new-gcc
          binutils
          ld-wrapper)))

(concatenate-manifests
  (list ;; gcc-manifest
        (specifications->manifest
            (list "patchelf"
                  "gcc-toolchain@11.4.0"
                  "llvm"
                  "clang"
                  "coreutils"
                  "findutils"
                  "tar"
                  "gzip"
                  "git"
                  "make"
                  "perl"
                  "bash"
                  "sed"
                  "grep"
                  "gawk"
                  "rust-toolchain@1.75.0"))))
