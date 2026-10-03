{ lib, pkgs }:

# `pathway-mcp <server> <session-id|-> <message>`: one turn of a Pathway `@server`
# chat, as Claude Code stream-json on stdout. Claude Code is the MCP client, so
# Pathway never speaks MCP itself; `claude` comes from the user's session.
#
# Each server authenticates with the sops secret of the same name, sent as a
# bearer token.

let
  servers = {
    linear = "https://mcp.linear.app/mcp";
  };

  configs = pkgs.linkFarm "pathway-mcp-configs" (lib.mapAttrsToList (name: url: {
    name = "${name}.json";
    path = pkgs.writeText "${name}.json" (builtins.toJSON {
      mcpServers.${name} = {
        type = "http";
        inherit url;
        headers.Authorization = "Bearer \${PATHWAY_MCP_TOKEN}";
      };
    });
  }) servers);

  prompt = ''
    You are answering inside Pathway, a small launcher popup. Be brief: a few
    lines or a short list, plain markdown, no headings. Act on requests
    directly with your tools rather than asking for confirmation.
  '';
in
pkgs.writeShellApplication {
  name = "pathway-mcp";
  runtimeInputs = with pkgs; [ coreutils jq ];
  text = ''
    server="$1" session="$2" message="$3"
    config="${configs}/$server.json"
    secret="''${XDG_CONFIG_HOME:-$HOME/.config}/sops-nix/secrets/$server"

    fail() {
      jq -nc --arg m "$1" '{type: "result", is_error: true, result: $m}'
      exit 1
    }

    [[ -r $config ]] || fail "Unknown MCP server: $server"
    [[ -r $secret ]] || fail "No API key for $server - add a \`$server\` sops secret."

    # Sessions are stored per working directory, so --resume needs a fixed one.
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/pathway-mcp"
    mkdir -p "$state"
    cd "$state"

    args=(
      -p "$message"
      --output-format stream-json --verbose
      --model sonnet
      --mcp-config "$config" --strict-mcp-config
      --tools "" --allowedTools "mcp__$server"
      --disable-slash-commands
      --append-system-prompt ${lib.escapeShellArg prompt}
    )
    [[ $session == - ]] || args+=(--resume "$session")

    PATHWAY_MCP_TOKEN="$(<"$secret")" AGENT_STATUS_IGNORE=1 exec claude "''${args[@]}"
  '';
}
