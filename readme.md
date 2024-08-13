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

## Usage  🐳

Via Docker Compose:

```yaml
services:
  samba:
    image: dockurr/samba
    container_name: samba
    environment:
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

  * ### How do I modify the credentials?

    You can set the `USER` and `PASS` environment variables to modify the credentials from their default values: user `samba` with password `secret`.

  * ### How do I modify the permissions?

    You can set `UID` and `GID` environment variables to change the user and group ID.

    To mark the share as read-only, add the variable `RW: false`.

  * ### How do I modify other settings?

    If you need more advanced features, you can completely override the default configuration by modifying the [smb.conf](https://github.com/dockur/samba/blob/master/smb.conf) file in this repo, and binding your custom config to the container like this:

    ```yaml
    volumes:
      - /example/smb.conf:/etc/samba/smb.conf
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
[Package]: 
https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fipitio%2Fbackage%2Fmaster%2Findex%2Fdockur%2Fsamba%2Fsamba.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
