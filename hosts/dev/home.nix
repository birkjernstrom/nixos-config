{ config, ... }:

{
  imports = [
    ../../home
  ];

  config.features = {
    programming = {
      python.enable = true;
      node.enable = true;
    };
  };
}
