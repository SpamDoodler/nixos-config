{config, pkgs, ...}:

{
  programs.yazi = {
    enable = true;

    settings = {

    };

    openers = {
      "open" = {
        default = [
          {
            run = "xdg-open '$1'", 
            desc = "Open with default system app" 
          };
        ];
      };

      "open.pdf" = {
        default = [
          {
            run = "zathura '$1'", 
            desc = "Open PDF with Zathura"; 
          };
        ];
      };

    };
  };
}
