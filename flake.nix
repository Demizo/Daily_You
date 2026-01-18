{
  description = "Flutter";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolsVersion = "35.0.1";
        platformToolsVersion = "35.0.2";
        ndkVersion = "28.2.13676358";
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          platformToolsVersion = platformToolsVersion;
          ndkVersion = ndkVersion;
          cmakeVersions = [ "3.22.1" ];
          includeNDK = true;
          buildToolsVersions = [
            buildToolsVersion
            "35.0.0"
            "34.0.0"
            "33.0.1"
          ];
          platformVersions = [
            "36"
            "35"
            "34"
            "33"
            "32"
            "31"
          ];
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs;
          mkShell rec {
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            NDK_VERSION = ndkVersion;
            JAVA_HOME = jdk17.home;
            FLUTTER_ROOT = flutter;
            DART_ROOT = "${flutter}/bin/cache/dart-sdk";
            buildInputs = [
              flutter
              androidSdk # The customized SDK that we've made above
              jdk17
            ];
          };
      }
    );
}
