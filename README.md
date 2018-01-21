# fsical-management

 A tool to manage the calendar of the Fachschaft Mathe/Physik Uni Regensburg 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system ([Raspberry Pi](https://www.raspberrypi.org/)).

### Prerequisites

#### D compiler
Either [DMD](https://dlang.org/download.html#dmd) or [LDC](https://github.com/ldc-developers/ldc#installation) is needed to compile the project. Additionally, the packagemanager [DUB](https://code.dlang.org/) is needed. Install via your distribution’s packagemanager if you are running linux or via [Homebrew](https://brew.sh/) if you are running OS X:
- Debian based systems:
```
sudo wget http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
sudo apt-get update && sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring
sudo apt-get update
# DMD:
sudo apt-get install dmd-compiler
# LDC:
sudo apt-get install ldc
# DUB:
sudo apt-get install dub
```
- Arch Linux:
```
# DMD:
sudo pacman -S dmd
# LDC:
sudo pacman -S ldc
# DUB:
sudo pacman -S dub
```
- OS X
```
# DMD:
brew install dmd
# LDC:
brew install ldc
# DUB:
brew install dub
```


#### MySQL or MongoDB
Access to a [MySQL](https://www.mysql.com/) (or its open source fork [MariaDB](https://mariadb.org/)) or a [MongoDB](https://www.mongodb.com/) server is needed. To install it locally, use your distribution’s packagemanager if you are running linux or [Homebrew](https://brew.sh/) if you are running OS X:
- Debian based systems:
```
# MariaDB:
sudo apt-get install mariadb
# MongoDB:
sudo apt-get install mongodb-org
```
- Arch Linux:
```
# MariaDB:
sudo pacman -S maraidb
# MongoDB:
sudo pacman -S mongodb
```
- OS X
```
# MariaDB:
brew install mariadb
# Mongo:
brew install mongodb
```

#### OpenSSL
The project depens on OpenSSL being available. Both OpenSSL-1.0 and OpenSSL-1.1 are supported, but in order to successfully use OpenSSL-1.1, the switch `--override-config vibe-d:tls/openssl-1.1` needs to be added to all `dub` commands.
OpenSSL should be available by default on most systems. If it is not available, use your distribution’s packagemanager to install it if you are running linux, or [Homebrew](https://brew.sh/) if you are running OS X:
- Debian based systems:
```
sudo apt-get install openssl
```
- Arch Linux:
```
sudo pacman -S openssl
```
- OS X
```
brew install openssl
```

### Installing

To install the project, you first need to clone the repository:
```
git clone https://github.com/fsimphy/fsical-management.git
```

Building the project is done by running the following command inside the project’s root directory:
```
dub build
```

To run the project, first make sure that the MySQL or MongoDB server is running. Then set up the database by running the following commands inside the project’s root directory:

#### MySQL

```
mysql -h <host> -u root -p < schema.sql
```

#### MongoDB

```
mongo <host>/FsicalManagement
> db.users.insert({ "username": "foo", "passwordHash": "$5$ZcsLcID1hIeYDr7ItwSJPdOOUP0FpXYXiHXs4O5XJI0=$/XWInm91lu1dMAi3dMSZSIJ+2hwZgrBF79rMuNc35Rc=", "privilege": NumberInt(2), "_id": "5988ef4ae6c19089a1a53b79" })
```
This will create a database called `FsicalManagement` and the neccessary tables. If you want to use a different database name, an already existing database or a different username, you need to adjust the above commands and / or the `schema.sql` file accordingly.

This also adds a default user named `foo` with password `bar`.

To actually run the project, simply run the following command in the project’s root directory:
```
dub run [-- options]
```
If you already built the project, you can also run it directly:
```
./generated/fsical-management [options]
```
See usage for a list of available options.

## Usage
```
Usage: fsical-management <options>

 -h --help           Prints this help screen.
 -v --verbose        Enables diagnostic messages (verbosity level 1).
    --vv, --vverbose Enables debugging output (verbosity level 2).
    --vvv            Enables high frequency debugging output (verbosity level
                     3).
    --vvvv           Enables high frequency trace output (verbosity level 4).
    --uid=<value>, --user=<value>
                     Sets the user name or id used for
                     privilege lowering.
    --gid=<value>, --group=<value>
                     Sets the group name or id used for
                     privilege lowering.
    -d <value>, --disthost=<value>
                     Sets the name of a vibedist server to
                     use for load balancing.
    --distport=<value>
                     Sets the port used for load
                     balancing.
    --database=<value>
                     The database system to use.
    --mongodb.host=<value>
                     The host of the MongoDB instance to
                     use.
    --mongodb.database=<value>
                     The name of the MongoDB database to
                     use.
    --mysql.host=<value>
                     The host of the MySQL instance to
                     use.
    --mysql.username=<value>
                     The username to use for logging into
                     the MySQL instance.
    --mysql.password=<value>
                     The password to use for logging into
                     the MySQL instance.
    --mysql.database=<value>
                     The name of the MySQL database to
                     use.
```

## Running the tests

To run the tests, run the following command in the project’s root directory:
```
dub test
```
This runs all available tests. To run only a specific test, run the following command in the project’s root directory:
```
dub test -- test.calendarwebapp.<module>.<testName>
```
See [unit-threaded](https://github.com/atilaneves/unit-threaded) for more information on available testing options.
## Deployment

Deploying the project on a Raspberry Pi requires some more work, because DMD is not able to build arm binaries and LDC is not available in the repositories of the major linux distributions for the Raspberry Pi.

We suggest using [Arch Linux ARM](https://archlinuxarm.org/), but using a different distribution such as [Raspbian](https://www.raspbian.org) should also be possible.

### Deployment to Arch Linux ARM
First install neccessary dependencies:
```
sudo pacman -S llvm gcc ncurses zlib
```
We will install LDC-1.6.0, which depens on `libtinfo`, which is contained in the `ncurses` package, but the version (`libtinfo.so.6.0`) is wrong (LDC needs `libtinfo.so.5`). It seems as though simply creating a symbolic link does the trick:
```
sudo ln -s /usr/lib/libtinfo.so /usr/lib/libtinfo.so.5
```
Be aware that this is quite hacky and might cause problems later on. It might be better to install `libtinfo.so.5` manually.

To install LDC-1.6.0 (and DUB), download and extract it in your home folder via the following commands:
```
wget https://github.com/ldc-developers/ldc/releases/download/v1.6.0/ldc2-1.6.0-linux-armhf.tar.xz
tar xf ldc2-1.6.0-linux-armhf.tar.xz
```
Then add it to your `PATH`:
```
export PATH=~/ldc2-1.6.0-linux-armhf/bin
```
You might want to add the previous command to your `.bashrc` (or similar) file so you don't have to retype it every time you want to use DUB or LDC.

Now you can build, run and test the project as explained in the earlier sections.
## Built With

* [DUB](https://code.dlang.org/) - Dependency Management
* [Poodinis](https://github.com/mbierlee/poodinis) - Dependency Injection Framework
* [unit-threaded](https://github.com/atilaneves/unit-threaded) - Testing Framework
* [vibe.d](https://vibed.org/) - Web Framework

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on the process for submitting issues and pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/fsimphy/fsical-management/tags). 

## Authors

* **Johannes Loher**

See also the list of [contributors](https://github.com/fsimphy/fsical-management/contributors) who participated in this project.

## License

This project is licensed under the MIT License, see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

Thanks a lot to the folks at the [D Programming Language Forum](https://forum.dlang.org/) and especially to [Sönke Ludwig](https://github.com/s-ludwig), the maintainer of [vibe.d](https://vibed.org/), for always helping out with technical questions.

