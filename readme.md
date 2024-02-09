<div align="center">
<img src="https://raw.githubusercontent.com/dockur/samba/master/.github/logo.png" title="Logo" style="max-width:100%;" width="256" />
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Pulls]][hub_url]

</div></h1>

Docker container of Samba, a re-implementation of the Windows SMB networking protocol.

## How to use

Via `docker-compose`

```yaml
version: "3"
services:
  samba:
    image: dockurr/samba
    container_name: samba
    environment:
      - "USER=samba"
      - "PASS=secret"
    ports:
      - 445:445
    volumes:
      - /home/example:/storage
    restart: on-failure
```

Via `docker run`

```bash
docker run -it --rm -p 445:445 -v "/home/example:/storage" -e "USER=samba" -e "PASS=secret" dockurr/samba
```

## Stars
[![Stars](https://starchart.cc/dockur/samba.svg?variant=adaptive)](https://starchart.cc/dockur/samba)

[build_url]: https://github.com/dockur/samba/
[hub_url]: https://hub.docker.com/r/dockurr/samba
[tag_url]: https://hub.docker.com/r/dockurr/samba/tags

[Build]: https://github.com/dockur/samba/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/samba/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/samba.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/samba/latest?arch=amd64&sort=semver&color=066da5
