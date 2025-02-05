{ config, ... }:

{
  imports = [
    ../../home
  ];

  config.features = {
    programming = {
      python.enable = false;
    };
  };
}
