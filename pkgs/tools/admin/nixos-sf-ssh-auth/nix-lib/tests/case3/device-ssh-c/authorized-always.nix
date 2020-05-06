{
  device-users = {
    "" = {
      ssh-groups = [
        "my-group-c-admin"
      ];
    };
    my-device-service-user = {
      ssh-groups = [
        "my-group-c-dev"
      ];
    };
    my-device-normal-user = {
      ssh-groups = [
        "my-group-c-support"
      ];
    };
  };
}
