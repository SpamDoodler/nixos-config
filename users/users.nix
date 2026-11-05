{pkgs, ...}: {
  users.users.spamdoodler = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "spamdoodler";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "dialout"
      "libvirtd"
      "gamemode"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDafdTz3yErBmSbxqL05ytMlRsvw35O76VK5eej8xrf/SkAenCM157U6rTdUPPoq/yPhAQtzOf+usi+HSciJu3EoxYOgm5Hq6Q6lY1B6X+DGsYiCxQ6124/NtnmtJopLpFHPyBsllV3M6xiq13JEiE75CUTqgnYnecQwtD2fezrQ27amyBkG4Oq6S4UGuttnUQnFx3MAF0v7urdwFDuHN1UQPU2tZJiUQhpmo2Js1aH5eTbBVjA1rVLwrgFW87eHqu5qB3tHE447TXXWCnZNvJy3yjgTcjbLPTxl/PrfCph3OWq/FHfV/+gam+vrw0Vjtxk/Sn6Mn0ofoZ5TA5BVCWPa+sNsBH9ciYySeQW5hZsgzPYBxomtTbLqWna6ynIVeXOVpEQV900VNXN1gyhCUjg4IMvmgbT2/Ilp0Ioq77Ap9eUP92qI3Y72s7R1fy+0KghbHYcwhpA0tX5o1Z62K8qwnNTrasEgQL25SRu3jtDMLLyCKxdEFVLKxqC32goVG6nqa3WQguPy5IrMyvy+tYrWpe3Q3VxVkS4xXwvwb8H5/vTxeYz5FiXfkLWjpjJv0IKyqOZpk3UAJZqxb/ypOGrXN/N7jvFa9aN5DEPe0LShJp/CGkXfZAzXt1PrjfJ8xMHB4yDspQ29AjT3/VWRFaeZUXEQ3TxoAR20vnrMac/6Q== raphael.senghaas@gmx.de"
    ];
    uid = 1000;
  };
}
