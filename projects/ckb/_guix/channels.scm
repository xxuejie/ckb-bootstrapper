(list (channel
        (name 'rustup)
        (url "https://github.com/declantsien/guix-rustup")
        (branch "master")
        (commit
          "bca5dd2bc75f2f0640a0d258957efa4734c7f550")
        (introduction
          (make-channel-introduction
            "325d3e2859d482c16da21eb07f2c6ff9c6c72a80"
            (openpgp-fingerprint
              "F695 F39E C625 E081 33B5  759F 0FC6 8703 75EF E2F5"))))
      (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (branch "master")
        (commit
          "4473f8ae902c2192cab6919363a9101ce9861e45")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
