<h1 align="center"><div align="center">
<a href="https://github.com/dockur/samba"><img src="https://raw.githubusercontent.com/dockur/samba/master/.github/logo.png" title="Logo" style="max-width:100%;" width="256" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Package]][pkg_url]
[![Pulls]][hub_url]

</div></h1>

Docker container of [Samba](https://www.samba.org/), an implementation of the SMB networking protocol.

## Features ✨

- Provides a lightweight SMB file server
- Configurable share name and credentials
- Supports multiple users via a list file
- Supports read-only and read-write shares
- Allows custom Samba configuration
- Works with Windows, macOS, and Linux clients
- Lightweight Alpine-based image

## Usage  🐳

##### Docker Compose:

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
      - ./samba:/storage
    restart: always
```

##### Docker CLI:

```bash
docker run -it --rm --name samba -p 445:445 -e "NAME=Data" -e "USER=samba" -e "PASS=secret" -v "${PWD:-.}/samba:/storage" docker.io/dockurr/samba
```

## Configuration ⚙️

### How do I choose which folder to share?

To choose your shared folder, include the following bind mount in your compose file:

```yaml
volumes:
  - ./samba:/storage
```

Replace the example path `./samba` with the desired folder or named volume.

### How do I change the share name?

You can change the name displayed to SMB clients with the `NAME` environment variable:

```yaml
environment:
  NAME: "Data"
```

### How do I connect to the shared folder?

On Windows, enter the following in File Explorer:

```text
\\192.168.0.2\Data
```

On macOS or Linux, use:

```text
smb://192.168.0.2/Data
```

Replace `192.168.0.2` with the IP address of the host and `Data` with the configured share name.

> [!NOTE]
>
> This container only provides the SMB file server and does not run a WS-Discovery service. As a result, the server will normally not appear automatically under **Network** in Windows.

### How do I change the credentials?

You can use the `USER` and `PASS` environment variables to configure the username and password:

```yaml
environment:
  USER: "samba"
  PASS: "secret"
```

The default username is `samba` and the default password is `secret`.

### How do I configure file ownership?

By default, the container automatically uses the user and group IDs of the shared `/storage` directory. If either ID is `0`, it falls back to `1000` for that value.

You can override the detected values with the `UID` and `GID` environment variables:

```yaml
environment:
  UID: "1002"
  GID: "1005"
```

This is useful when the ownership of the mounted directory does not match the IDs you want Samba to use.

### How do I make the share read-only?

Set `RW` to `false`:

```yaml
environment:
  RW: "false"
```

This changes the Samba share to read-only.

### How do I provide a custom Samba configuration?

For advanced configuration, you can provide your own `smb.conf`. The default [smb.conf](https://github.com/dockur/samba/blob/master/smb.conf) can be used as a starting point.

Bind your custom configuration to the container like this:

```yaml
volumes:
  - ./smb.conf:/etc/samba/smb.conf
```

### How do I configure multiple users?

To configure multiple users, bind a [users.conf](https://github.com/dockur/samba/blob/master/users.conf) file to the container:

```yaml
volumes:
  - ./users.conf:/etc/samba/users.conf
```

Each non-empty line defines one user using the following format:

```text
username:UID:groupname:GID:password:homedir
```

For example:

```text
john:1001:users:1001:secret:/storage
jane:1002:users:1001:anothersecret:/storage
```

The fields are:

- `username` — Username of the account.
- `UID` — Numeric user ID.
- `groupname` — Name of the primary group.
- `GID` — Numeric group ID.
- `password` — Password of the Samba account. It cannot contain `:`, `\n`, or `\r`.
- `homedir` — Optional home directory. Defaults to `/storage` when omitted.

Lines starting with `#` and empty lines are ignored.

## Stars 🌟
[![Stargazers](https://raw.githubusercontent.com/star-stats/stars/refs/heads/data/charts/dockur-samba.svg)](https://github.com/dockur/samba/stargazers)

[build_url]: https://github.com/dockur/samba/
[hub_url]: https://hub.docker.com/r/dockurr/samba
[tag_url]: https://hub.docker.com/r/dockurr/samba/tags
[pkg_url]: https://github.com/dockur/samba/pkgs/container/samba

[Build]: https://github.com/dockur/samba/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/samba/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/samba.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/samba/latest?arch=amd64&sort=semver&color=066da5
[Package]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fipitio.github.io%2Fbackage%2Fdockur%2Fsamba%2Fsamba.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
