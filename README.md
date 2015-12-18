# Cozy Archlinux

An Archlinux port of Cozy, the personal cloud that you can hack, host and delete. This port is packaged with either the Apache 2 web server or the Nginx one, or with none of them.

## Installation

There are two ways of installing these packages.

### Via AUR

The stable versions of these packages are available on the official Archlinux User Repository. You can install them with the AUR client of your choice. For example, with yaourt:

```
yaourt -S cozy-apache
yaourt -S cozy-nginx
yaourt -S cozy-standalone
```

Please keep in mind that Cozy is currently only available with Node.JS 0.10.x, that's why we have to use another package than the `nodejs` package located in the official Archlinux repositories (v4.x). To have the platform running on Archlinux, we need to use the AUR package `nodejs10`, which will compile Node.JS v0.10.40, and can take a long time on small configurations. As the package is included in the dependances, you don't need to worry about previously installing the v0.10.x, but just keep in mind that it may take a while.

### Via `makepkg`

Another way to install these packages is to clone this repository, then enter the selected package's directory and run `makepkg -si`. This will install the package with all the needed dependencies.

**Caution:** This wil **NOT** install the dependencies located in AUR. If you chose to install the package this way, you'll need to manually install `cozy-indexer` and `nodejs10` **before** installing the chosen package.

## Packages description

### `cozy-apache` and `cozy-nginx`

These two are packages which groups Cozy with one of the mentionned web servers. You can find them on this repository by browsing the folder named after the web server they are related to.

Since Cozy is constitued with several bricks, we need a reverse proxy to link them all with the others. For this purpose, we use an additional web server. These packages are aiming at providing an easy way to install the platform, with zero additional configuration needed, including the webserver. Install one if this package, direct your browser to your server's FQDN (the one you filled in the installation), and here you go, your Cozy is up and running.

### `cozy-standalone`

As some people prefer using other software than Nginx or Apache 2 for reverse proxying, this package provides only the platform, without any web server nor configuration for it.

If you want to refer to a configuration file for Nginx or Apache 2 to build your own one, you can find them on the official [repository](https://github.com/cozy/cozy-debian) for the Debian/Ubuntu Cozy package.

## What is Cozy?

![Cozy Logo](https://raw.github.com/mycozycloud/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](http://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you. You install only the applications you want. You can build your
own one too.

## Get in touch

If you want to discuss or contribute to these packages, here are all the ways to contact me:

* **By e-mail**: <brendan@cozycloud.cc>
* **On the Cozy forums**: In [french](https://forum.cozy.io/t/cozy-sur-archlinux/1341) or in [english](https://forum.cozy.io/t/cozy-on-archlinux/1342)
* **On IRC**: #cozycloud on irc.freenode.net, you'll find me there as *Dragavnir*
* **On Twitter**: [@BrenAbolivier](https://twitter.com/BrenAbolivier)

If you're around Brest or Rennes (France), we can even meet to talk a bit around a drink :-)
