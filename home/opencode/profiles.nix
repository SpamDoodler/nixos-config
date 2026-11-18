{lib, ...}: let
  root = ./profiles;
  tiers = ["LUNA" "TERRA" "SOL" "ASTRA"];
  prefix = "opencode-research/";
  names = dir: lib.attrNames (builtins.readDir (root + "/${dir}"));
  baseAgents = map (file: let
    text = builtins.readFile (root + "/agents/${file}");
    tier = lib.findFirst (key: lib.hasInfix "model: @${key}@" text) null tiers;
  in {
    name = lib.removeSuffix ".md" file;
    inherit file text tier;
  }) (names "agents");
  variants = {
    r-worker-terra-low = {
      base = "r-worker-terra";
      tier = "terra-low";
    };
    r-worker-sol-low = {
      base = "r-worker-sol";
      tier = "sol-low";
    };
    r-verifier-s-low = {
      base = "r-verifier-s";
      tier = "sol-low";
    };
    r-worker-astra-max = {
      base = "r-worker-astra";
      tier = "astra-max";
    };
    r-probe-terra-low = {
      base = "r-probe-terra";
      tier = "terra-low";
    };
    r-probe-sol-low = {
      base = "r-probe-terra";
      tier = "sol-low";
    };
    rv-probe-terra-low = {
      base = "rv-probe-terra";
      tier = "terra-low";
    };
    rv-probe-sol-low = {
      base = "rv-probe-sol";
      tier = "sol-low";
    };
  };
  agents =
    baseAgents
    ++ lib.mapAttrsToList (name: variant: let
      base = lib.findFirst (agent: agent.name == variant.base) (throw "Missing profile ${variant.base}") baseAgents;
    in
      base
      // {
        inherit name;
        file = "${name}.md";
        deployment = variant.tier;
        text =
          if lib.hasPrefix "r-probe-" name
          then lib.replaceStrings ["probe-terra/" "Terra blind"] ["probe-${variant.tier}/" "${variant.tier} blind"] base.text
          else base.text;
      })
    variants;
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
  installedAgents = builtins.filter (agent: agent.name != "r-worker-terra") agents;
  deployment = agent:
    if agent ? deployment
    then agent.deployment
    else if agent.tier == "TERRA" && !lib.hasInfix "-probe-" agent.name
    then "terra-low"
    else lib.toLower agent.tier;
  markdown = dir: files:
    lib.listToAttrs (map (file:
      lib.nameValuePair "${prefix}${dir}/${file}" {
        source = root + "/${dir}/${file}";
      })
    files);
in {
  plugin = {
    package = "${root}";
    options.tiers = lib.listToAttrs (map (agent: lib.nameValuePair agent.name (deployment agent)) installedAgents);
  };
  files =
    lib.listToAttrs (map (agent:
      lib.nameValuePair "${prefix}agents/${agent.file}" {
        text = renderAgent agent;
      })
    installedAgents)
    // markdown "commands" (names "commands")
    // markdown "skills" (names "skills");
}
