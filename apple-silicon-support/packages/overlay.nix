final: prev: {
  linux-asahi = final.callPackage ./linux-asahi { };
  uboot-asahi = final.callPackage ./uboot-asahi { };
  mesa-asahi-edge = final.callPackage ./mesa-asahi-edge { };
}
