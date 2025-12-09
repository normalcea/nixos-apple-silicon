{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./kernel
    ./peripheral-firmware
    ./boot-m1n1
    ./sound
  ];

  config =
    let
      cfg = config.hardware.asahi;
    in
    lib.mkIf cfg.enable {
      nixpkgs.overlays = lib.mkBefore [ cfg.overlay ];

      hardware.asahi.pkgs =
        if cfg.pkgsSystem != "aarch64-linux" then
          import (pkgs.path) {
            crossSystem.system = "aarch64-linux";
            localSystem.system = cfg.pkgsSystem;
            overlays = [ cfg.overlay ];
          }
        else
          pkgs;

      # 900 is higher priority than mkDefault but lower than just setting
      hardware.graphics.package = lib.mkOverride 900 (
        lib.warnIf (lib.versionAtLeast pkgs.mesa.version "25.3") ''
          Mesa 25.3 is known to cause crashes in Firefox on Asahi GPUs.
          Please pin nixpkgs c5ae371f1a6a7fd27823 or earlier if affected.
          See https://github.com/nix-community/nixos-apple-silicon/issues/380
          for more info.'' pkgs.mesa
      );

      environment.etc."drirc".text = ''
        <?xml version="1.0" standalone="yes"?>
        <!--

        ============================================
        Application bugs worked around in this file:
        ============================================

        * web broswer OpenGL renderer override fo asahi
          Several web sites (paypal.com, etsy.com) apparently block on "Apple" in
          WebGL renderer strings when the UA reports Linux as OS.
          See https://github.com/webcompat/web-bugs/issues/189524

        -->

        <!DOCTYPE driconf [
           <!ELEMENT driconf      (device+)>
           <!ELEMENT device       (application | engine)+>
           <!ATTLIST device       driver CDATA #IMPLIED
                                  device CDATA #IMPLIED>
           <!ELEMENT application  (option+)>
           <!ATTLIST application  name CDATA #REQUIRED
                                  executable CDATA #IMPLIED
                                  executable_regexp CDATA #IMPLIED
                                  sha1 CDATA #IMPLIED
                                  application_name_match CDATA #IMPLIED
                                  application_versions CDATA #IMPLIED>
           <!ELEMENT engine       (option+)>

           <!-- engine_name_match: A regexp matching the engine name -->
           <!-- engine_versions: A version in range format
                     (version 1 to 4 : "1:4") -->

           <!ATTLIST engine       engine_name_match CDATA #REQUIRED
                                  engine_versions CDATA #IMPLIED>

           <!ELEMENT option       EMPTY>
           <!ATTLIST option       name CDATA #REQUIRED
                                  value CDATA #REQUIRED>
        ]>

        <driconf>
            <device driver="asahi">
      ''
      + (lib.concatStringsSep "\n" (
        lib.map (bin: ''
          <application name="${bin}" executable="${bin}">
             <option name="force_gl_renderer" value="AGX G1Nx"/>
          </application>
          <application name="${bin} Wrapped" executable=".${bin}-wrapped">
             <option name="force_gl_renderer" value="AGX G1Nx"/>
          </application>
        '') cfg.webSecurityCompat
      ))
      + ''
          </device>
        </driconf>
      '';
    };

  options.hardware.asahi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the basic Asahi Linux components, such as kernel and boot setup.
      '';
    };

    pkgsSystem = lib.mkOption {
      type = lib.types.str;
      default = "aarch64-linux";
      description = ''
        System architecture that should be used to build the major Asahi
        packages, if not the default aarch64-linux. This allows installing from
        a cross-built ISO without rebuilding them during installation.
      '';
    };

    webSecurityCompat = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "firefox"
        "firefox-esr"
        "firefox-beta"
        "librewolf"
        "chromium"
        "chromium-browser"
        "vivaldi-bin"
        "iceweasel"
        "epiphany"
        "konqueror"
        "falkon"
        "waterfox"
        "seamonkey"
      ];
      description = ''
        Apply mesa workaround to specified browser binaries to avoid
        false-positives on certain websites, including but not limited
        to Paypal, Etsy and WSJ.

        The default list contains a best-effort collection of
        web-browsers, if a browser you use is not listed here, append
        its browser binary here.
      '';
    };

    pkgs = lib.mkOption {
      type = lib.types.raw;
      description = ''
        Package set used to build the major Asahi packages. Defaults to the
        ambient set if not cross-built, otherwise re-imports the ambient set
        with the system defined by `hardware.asahi.pkgsSystem`.
      '';
    };

    overlay = lib.mkOption {
      type = lib.mkOptionType {
        name = "nixpkgs-overlay";
        description = "nixpkgs overlay";
        check = lib.isFunction;
        merge = lib.mergeOneOption;
      };
      default = import ../packages/overlay.nix;
      defaultText = "overlay provided with the module";
      description = ''
        The nixpkgs overlay for asahi packages.
      '';
    };
  };
}
