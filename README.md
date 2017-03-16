# Redis.app

### The easiest way to get started with Redis on the Mac

*Just download, drag to the applications folder, and double-click.*

![Screenshot](https://jpadilla.github.io/redisapp/assets/img/screenshot.png)

### [Download](http://jpadilla.github.io/redisapp)

--

### Version numbers

Version numbers of this project (Redis.app) try to communicate the version of the included Redis binaries bundled with each release.

The version number also includes a build number which is used to indicate the current version of Redis.app and it's independent from the bundled Redis's version.

### Adding Redis binaries to your path

If you need to add the Redis binaries to your path you can do so by adding the following to your `~/.bash_profile`.

```bash
# Add Redis.app binaries to path
PATH="/Applications/Redis.app/Contents/Resources/Vendor/redis/bin:$PATH"
```

Or using the `path_helper` alternative:
 
 ```bash
sudo mkdir -p /etc/paths.d &&
echo /Applications/Redis.app/Contents/Resources/Vendor/redis/bin | sudo tee /etc/paths.d/redisapp
 ```
 
### Installing with Homebrew Cask

You can also install Redis.app with [Homebrew Cask](http://caskroom.io/).

```bash
$ brew cask install redis-app
```

### Credits

Forked and adapted from [Mongodb.app](https://github.com/gcollazo/mongodbapp). Site design by [Giovanni Collazo](https://twitter.com/gcollazo).
