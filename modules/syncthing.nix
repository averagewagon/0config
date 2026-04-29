_:

{
  # Add new machines here when I'm done configuring them and update other configs
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        # Phone (introducer, since its config isn't managed by Nix anyways)
        ginger = {
          id = "ROA5SZQ-OA33NRK-2NNBO5R-QVVW3FQ-DBFUWP6-XTQ4UKJ-M2D66T6-UAFPFAQ";
          introducer = true;
        };

        # Laptop
        saffron.id = "T2F7ICT-EMNBQH6-TBDQ4DE-7X7J57J-QCGWIS2-VXBN4HB-LRGNZUZ-AFI5IQF";

        # DigitalOcean server
        cayenne.id = "WWUKSOV-7RTMEK5-464TFFY-JHMUAPJ-EOO7I5I-L4NB4E6-UHB5357-SP636QU";

        # Hetzner server
        horseradish.id = "PKN3I6Q-MPHESJ5-CTBBLUV-TAEN5KK-5UA27JE-26EUKCL-CVSP74A-RG237QD";

        # Selfhost server
        sh-sassafras.id = "4PJJBRC-HM7M4I7-FUZYMAP-3XXJ5P5-UHDIY67-NA5X53V-UW7H2IF-PMISLAB";
      };
      folders."~/0everything" = {
        id = "0everything";
        order = "newest";
        versioning = {
          type = "staggered";
          params.maxAge = "31536000"; # 1 year in seconds
        };
        devices = [
          "ginger"
          "cayenne"
          "saffron"
          "horseradish"
          "sh-sassafras"
        ];
      };
    };
  };
}
