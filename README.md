# kafka-deb-packaging

Debian packaging for binary distribution of Apache Kafka 0.10.0.1 with `fpm`.
Targeted on Debian 8 and systemd.

Takes the binary distribution of kafka and prepares a package.

Adds:
- systemd unit file for kafka.service
- kafka's user management
- 1etc/default/kafka` with heap opt and ulimits ready to be changed.
- slightly changed default config (see `etc/kafka/server.properties`)
- log4j.properties (ready to be changed in `etc/kafka/log4j.properties`)

## Kafka user management

According to debian guidelines kafka user will not be dropped on package deletion - only locked (postrm script).

On installation of a package the user will be created, if not exists.
If it exists - unlocked.

## Kafka folders and binary locations

Kafka scripts are heavily using the `$base_dir` to refer to jars.
As of kafka 0.8.1 the `$base_dir` was hardcoded to be the parent folder of `bin`.

Some other scripts on github have kafka packaged to `/usr/lib/kafka` (and they have `bin`, and `libs` inside), this approach does not comply with [FHS](http://www.pathname.com/fhs/).

The developers and admins usually have slightly different views where the files should reside.
This package takes the admins paradigm, because admins work at most with the package in the end.

```
| Locations              | This package          | Developers
-------------------------------------------------------------
| Pid file               | /var/run/*.pid        |
| Kafka message logs dir | /var/lib/kafka        |
| kafka user $HOME       | /var/lib/kafka        |
| kafka $base_dir        | /usr/lib/kafka        |
| Binary files dir*      | /usr/bin              | $base_dir/bin/
| Librariers dir*        | /usr/lib/kafka/libs   | $base_dir/libs/
| Configs                | /etc/kafka/*          | $base_dir/config/
| Logs                   | /var/log/storm        | $base_dir/logs/
| Init script            | /etc/init.d/kafka     |
| Kafka "default"        | /etc/default/kafka    |
-------------------------------------------------------------
```

\* The `bin` folder with binary files have to have same parent folder with `libs`.
I don't like that bins are in `/usr/lib/kafka/bin` and not in `/usr/bin`, but they were [written that way in 0.8.1](https://github.com/apache/kafka/blob/0.8.1/bin/kafka-run-class.sh#L23), that they depend on parent folder content and look jars there, in `libs` subdirectory.

I am looking forward to have kafka fully compatible to FHS.

So far there are several symlinks in the package to make the package a little closer to the FHS.

```bash
# assume $base_dir is /usr/lib/kafka/

/usr/bin/kafka-console-consumer -> $base_dir/bin/kafka-console-consumer.sh
/usr/bin/kafka-* -> $base_dir/bin/kafka-*

# the zookeeper is intentionally omitted here.

# the links point to real locations, to make it possible for example,
# for /var/log/kafka to be on different partition.
$base_dir/config -> /etc/kafka
$base_dir/logs -> /var/log/kafka

```
## Logging

Kafka is using `slf4j`, and there is `log4j` config in `/etc/kafka`

## Kafka heap optimization:

`KAFKA_HEAP_OPTS` is set in `/etc/default/kafka` and is used by systemd unit.
Kafka opens lots of files, so in most cases `ulimit` for opened files should be changed from default.
This is done in `kafka.service` unit file.
You may [override this](http://askubuntu.com/questions/659267/how-do-i-override-or-configure-systemd-services) with your scm system.

## Distribution support

Yet `build.sh` script was developed for systemd and tested only under debian 8 (can also work on other dists that support `systemd` and `*.deb`).
This script is building debian package, but using `fpm`, so it should also be capable of building the `rpm` package.

## Building with Docker

First, change the `build.sh` to add a packaging suffix to the package.

Then, prepare docker image and enter the docker container.
```
docker build -t kafka-deb-builder .
docker run -t -i --rm --name kafka-deb-builder -v ${PWD}:/mnt/workdir kafka-deb-builder
```

Run `./build.sh` in docker.

The script will create a kafka package in project directory and also `SAMPLE_LAYOUT.txt` from the package.


## TODO:

- cleanup
- use pushd build in bootstrap()
- add a notes about environment in README
