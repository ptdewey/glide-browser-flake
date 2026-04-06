{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  wrapGAppsHook3,
  patchelfUnstable,

  # Build inputs (needed by autoPatchelfHook for linking)
  alsa-lib,
  atk,
  cairo,
  dbus,
  dbus-glib,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libX11,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libxcb,
  libXtst,
  pango,

  # Runtime dependencies (LD_LIBRARY_PATH)
  cups,
  ffmpeg_7,
  libglvnd,
  libgbm,
  libnotify,
  libpulseaudio,
  libva,
  pciutils,
  pipewire,
  udev,
  vulkan-loader,
  xdg-utils,
  adwaita-icon-theme,
}:

let
  version = "0.1.61a";

  sources = {
    x86_64-linux = {
      url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
      hash = "sha256-oxxaz+sQfwCbsfxYcHPM3aQ1BxP0CEz70BTlmsi/5R4=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  runtimeLibs = lib.makeLibraryPath [
    alsa-lib
    atk
    cairo
    cups
    dbus
    dbus-glib
    ffmpeg_7
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libva
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libxcb
    libXtst
    pango
    pciutils
    pipewire
    udev
    vulkan-loader
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation {
  pname = "glide-browser";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  # The tarball extracts to a `glide/` directory
  sourceRoot = "glide";

  nativeBuildInputs = [
    autoPatchelfHook
    patchelfUnstable
    makeWrapper
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    dbus
    dbus-glib
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libxcb
    libXtst
    pango
    stdenv.cc.cc.lib
  ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = [ "--no-clobber-old-sections" ];

  runtimeDependencies = [
    pciutils
    libva
  ];

  appendRunpaths = [
    "${pipewire}/lib"
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "glide-browser";
      desktopName = "Glide Browser";
      genericName = "Web Browser";
      exec = "glide --name glide-browser %U";
      icon = "glide-browser";
      comment = "Browse the web with Glide";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      startupNotify = true;
      startupWMClass = "glide-browser";
      actions = {
        new-window = {
          name = "New Window";
          exec = "glide --new-window %U";
        };
        new-private-window = {
          name = "New Private Window";
          exec = "glide --private-window %U";
        };
      };
    })
  ];

  dontConfigure = true;
  dontBuild = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/glide
    cp -r . $out/lib/glide

    # Install icons
    for size in 16 32 48 64 128; do
      icon_dir=$out/share/icons/hicolor/''${size}x''${size}/apps
      mkdir -p "$icon_dir"
      cp $out/lib/glide/browser/chrome/icons/default/default''${size}.png \
        "$icon_dir/glide-browser.png"
    done

    runHook postInstall
  '';

  postFixup = ''
    # Wrap the main binary with LD_LIBRARY_PATH and other env vars.
    # The binary must be in lib/glide/ because it resolves paths relative to itself.
    chmod +x $out/lib/glide/glide

    makeWrapper $out/lib/glide/glide $out/bin/glide \
      --prefix LD_LIBRARY_PATH : "${runtimeLibs}" \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --suffix XDG_DATA_DIRS : "${adwaita-icon-theme}/share" \
      --suffix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --set MOZ_APP_LAUNCHER glide \
      --set MOZ_LEGACY_PROFILES 1 \
      --set MOZ_ALLOW_DOWNGRADE 1 \
      --set-default MOZ_ENABLE_WAYLAND 1 \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = "Glide Browser - a Firefox-based web browser";
    homepage = "https://glide-browser.app";
    license = lib.licenses.mpl20;
    maintainers = [ ];
    platforms = builtins.attrNames sources;
    mainProgram = "glide";
  };
}
