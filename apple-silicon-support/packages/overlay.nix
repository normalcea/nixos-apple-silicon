final: prev: {
  linux-asahi = final.callPackage ./linux-asahi { };
  asahi-fwextract = final.callPackage ./asahi-fwextract { };
  alsa-ucm-conf-asahi = final.callPackage ./alsa-ucm-conf-asahi { };
}
