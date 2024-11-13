<div align="center">
<a href="https://github.com/dockur/samba"><img src="https://raw.githubusercontent.com/dockur/samba/master/.github/logo.png" title="Logo" style="max-width:100%;" width="256" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Package]][pkg_url]
[![Pulls]][hub_url]

</div></h1>

Docker container of [Samba](https://www.samba.org/), an implementation of the Windows SMB networking protocol.
Original container forked from [dockur/samba](https://github.com/dockur/samba).

This fork is configured to focus more on implementing a multi-user share using Samba homes shares.

## TODO:
- [ ] Continue modifying container to further fit samba homes share
- [ ] Finish updating README.md

## Building
Build with buildkit!

Run:
`DOCKER_BUILDKIT=1 docker build . -t [registry:tag]` inside of this repository's directory.

Or have the following configuration in your `daemon.json`
```json
{
    "features": {
        "buildkit": true
    }
}
```
And build normally.

For more information, refer to the [offical dockerdocs](https://docs.docker.com/build/buildkit/#getting-started)

## Usage  🐳

Via Docker Compose:

```yaml
services:
  samba:
    image: dockurr/samba
    container_name: samba
    environment:
      NAME: "Data"
      USER: "samba"
      PASS: "secret"
    ports:
      - 445:445
    volumes:
      - /home/example:/storage
```

Via Docker CLI:

```bash
docker run -it --rm -p 445:445 -e "USER=samba" -e "PASS=secret" -v "/home/example:/storage" dockurr/samba
```

## Configuration ⚙️

### How do I choose the location of the shared folder?

To change the location of the shared folder, include the following bind mount in your compose file:

```yaml
volumes:
  - /home/example:/storage
```

Replace the example path `/home/example` with the desired folder.

### How do I modify the display name of the shared folder?

You can change the display name of the shared folder by adding the following environment variable:

```yaml
environment:
  NAME: "Data"
```  

### How do I connect to the shared folder?

To connect to the shared folder enter: `\\192.168.0.2\Data` in Windows Explorer.

> [!NOTE]
> Replace the example IP address above with that of your host.

### How do I modify the default credentials?

You can set the `USER` and `PASS` environment variables to modify the credentials from their default values: user `samba` with password `secret`.

```yaml
environment:
  USER: "samba"
  PASS: "secret"
```

### How do I modify the permissions?

You can set `UID` and `GID` environment variables to change the user and group ID.

```yaml
environment:
  UID: "1002"
  GID: "1005"
```

To mark the share as read-only, add the variable `RW: "false"`.

### How do I modify other settings?

If you need more advanced features, you can completely override the default configuration by modifying the [smb.conf](https://github.com/dockur/samba/blob/master/smb.conf) file in this repo, and binding your custom config to the container like this:

```yaml
volumes:
  - /example/smb.conf:/etc/samba/smb.conf
```

### How do I configure multiple users?

If you want to configure multiple users, you can bind the [users.conf](https://github.com/dockur/samba/blob/master/users.conf) file to the container as follows:

```yaml
volumes:
  - /example/users.conf:/etc/samba/users.conf
```

## Stars 🌟
[![Stars](https://starchart.cc/dockur/samba.svg?variant=adaptive)](https://starchart.cc/dockur/samba)

[build_url]: https://github.com/dockur/samba/
[hub_url]: https://hub.docker.com/r/dockurr/samba
[tag_url]: https://hub.docker.com/r/dockurr/samba/tags
[pkg_url]: https://github.com/dockur/samba/pkgs/container/samba

[Build]: https://github.com/dockur/samba/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/samba/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/samba.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/samba/latest?arch=amd64&sort=semver&color=066da5
[Package]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fipitio.github.io%2Fbackage%2Fdockur%2Fsamba%2Fsamba.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
