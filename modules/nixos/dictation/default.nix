{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.dictation;
  hypr = import ../hyprland/lib.nix { inherit lib; };
  inherit (hypr) bind mod exec;

  whisper = pkgs.whisper-cpp-vulkan;

  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q8_0.bin";
    sha256 = "18arw8jbwpyggv0j6k5cf7n0964rafr5km7hw7hrsg3726fbczii";
  };

  vadModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin";
    sha256 = "1kx29v0b93x235cqgr17y110lby7yzng72g4bk8gp49bsjc0v519";
  };

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [ coreutils gnused jq curl pipewire wtype wl-clipboard libnotify ];
    runtimeEnv.DICTATE_PORT = toString cfg.port;
    text = builtins.readFile ./dictate.sh;
  };
in
{
  options.userSettings.dictation = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Local voice dictation (whisper.cpp) on SUPER+D";
    };

    port = mkOption {
      type = types.port;
      default = 8178;
    };

    language = mkOption {
      type = types.str;
      default = "en";
      description = "Whisper language code; auto detects per recording at ~1s extra latency";
    };

    prompt = mkOption {
      type = types.str;
      default = "Polar, NixOS, Hyprland, Quickshell, Claude, Linear, GitHub, TypeScript, Python.";
      description = "Initial prompt, mostly for spelling vocabulary Whisper would otherwise guess at";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ dictate ];

    systemd.user.services.whisper-server = {
      Unit = {
        Description = "whisper.cpp transcription server";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = escapeShellArgs [
          "${whisper}/bin/whisper-server"
          "--model" "${model}"
          "--host" "127.0.0.1"
          "--port" (toString cfg.port)
          "--language" cfg.language
          "--prompt" cfg.prompt
          "--threads" "4"
          "--vad"
          "--vad-model" "${vadModel}"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    wayland.windowManager.hyprland.settings.bind = [
      (bind (mod "D") (exec "dictate toggle"))
      (bind (mod "SHIFT + D") (exec "dictate cancel"))
    ];
  };
}
