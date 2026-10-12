{ pkgs }:

# Direct Linear API calls for Pathway, where going through pathway-mcp would be
# needlessly slow:
#
#   pathway-linear teams                  JSON array of { key, name }
#   pathway-linear create <team> <title>  create an issue assigned to you, then
#                                         report it as a notification
pkgs.writeShellApplication {
  name = "pathway-linear";
  runtimeInputs = with pkgs; [ coreutils curl jq libnotify xdg-utils ];
  # GraphQL variables are `$name` inside single-quoted queries.
  excludeShellChecks = [ "SC2016" ];
  text = ''
    secret="''${XDG_CONFIG_HOME:-$HOME/.config}/sops-nix/secrets/linear"

    fail() {
      notify-send -a Linear -u critical "Linear task not created" "$1"
      exit 1
    }

    gql() {
      jq -n --arg q "$1" --argjson v "$2" '{query: $q, variables: $v}' |
        curl -sf https://api.linear.app/graphql \
          -H "Authorization: $(<"$secret")" \
          -H 'Content-Type: application/json' \
          --data @-
    }

    [[ -r $secret ]] || fail "No API key - add a \`linear\` sops secret."

    case "''${1:-}" in
    teams)
      gql '{ teams(first: 250) { nodes { key name } } }' '{}' |
        jq -c '.data.teams.nodes | sort_by(.key)'
      ;;
    create)
      team="$2" title="$3"
      ids="$(gql 'query($key: String!) { viewer { id } teams(filter: { key: { eq: $key } }) { nodes { id } } }' \
        "$(jq -n --arg key "$team" '{key: $key}')")" || fail "Could not reach Linear."
      team_id="$(jq -r '.data.teams.nodes[0].id // empty' <<<"$ids")"
      viewer="$(jq -r '.data.viewer.id // empty' <<<"$ids")"
      [[ -n $team_id ]] || fail "No team with key $team."

      issue="$(gql 'mutation($input: IssueCreateInput!) { issueCreate(input: $input) { issue { identifier url } } }' \
        "$(jq -n --arg team "$team_id" --arg me "$viewer" --arg title "$title" \
          '{input: {teamId: $team, assigneeId: $me, title: $title}}')")" || fail "Could not reach Linear."
      identifier="$(jq -r '.data.issueCreate.issue.identifier // empty' <<<"$issue")"
      url="$(jq -r '.data.issueCreate.issue.url // empty' <<<"$issue")"
      [[ -n $identifier ]] || fail "$(jq -r '.errors[0].message // "Request failed."' <<<"$issue")"

      action="$(notify-send -a Linear -A open=Open "Created $identifier" "$title" || true)"
      [[ $action != open ]] || xdg-open "$url"
      ;;
    *)
      echo "usage: pathway-linear {teams|create <team> <title>}" >&2
      exit 2
      ;;
    esac
  '';
}
