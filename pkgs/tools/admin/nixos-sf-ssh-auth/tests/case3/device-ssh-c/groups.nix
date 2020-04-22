{
  ssh-groups = {
    my-group-c-admin = {
      members = [
        "my-ssh-user-c0"
      ];
    };
    my-group-c-support = {
      members = [
        "my-ssh-user-c1"
        "my-ssh-user-c2"
      ];
    };
    my-group-c-dev = {
      members = [
        "my-ssh-user-c2"
      ];
    };
  };
}
