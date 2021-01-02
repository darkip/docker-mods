# Docker mod for `deluge` image upgrading `libtorrent`

This mod upgrades the version of `libtorrent` in the `deluge` image during container start.

In the `deluge` docker arguments, set an environment variable
`DOCKER_MODS=ghcr.io/darkip/linuxserver-mods:deluge-libtorrent-upgrade`.

If adding multiple mods, enter them in an array separated by `|`, such as
`DOCKER_MODS=ghcr.io/darkip/linuxserver-mods:deluge-libtorrent-upgrade|DOCKER_MODS=ghcr.io/darkip/linuxserver-mods::other-mod`
