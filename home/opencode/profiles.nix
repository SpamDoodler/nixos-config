{lib, ...}: let
  root = ./profiles;
  tiers = ["LUNA" "TERRA" "SOL" "ASTRA"];
  prefix = "opencode-research/";
  names = dir: lib.attrNames (builtins.readDir (root + "/${dir}"));
  agents = map (file: let
    text = builtins.readFile (root + "/agents/${file}");
    tier = lib.findFirst (key: lib.hasInfix "model: @${key}@" text) null tiers;
  in {
    name = lib.removeSuffix ".md" file;
    inherit file text tier;
  }) (names "agents");
  renderAgent = agent:
    lib.replaceStrings
    ["model: @${agent.tier}@\n" "permissions:\n"]
    [
      ""
      # The regular build profile auto-allows Python. In these profiles a
      # worker needs explicit approval, unless its own rules deny shell.
      ("permissions:\n  - {action: shell, resource: \"python*\", effect: ask}\n  - {action: shell, resource: \"pytest*\", effect: ask}\n"
        + lib.optionalString (lib.hasPrefix "rv-" agent.name) "  - {action: shell, resource: \"*\", effect: deny}\n")
    ]
    agent.text;
  markdown = dir: files:
    lib.listToAttrs (map (file:
      lib.nameValuePair "${prefix}${dir}/${file}" {
        source = root + "/${dir}/${file}";
      })
    files);
in {
  plugin = {
    package = "${root}";
    options.tiers = lib.listToAttrs (map (agent: lib.nameValuePair agent.name (lib.toLower agent.tier)) agents);
  };
  files =
    lib.listToAttrs (map (agent:
      lib.nameValuePair "${prefix}agents/${agent.file}" {
        text = renderAgent agent;
      })
    agents)
    // markdown "commands" (names "commands")
    // markdown "skills" (names "skills");
}
