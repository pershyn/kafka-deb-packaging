#!/bin/bash
set -e
set -u

PKG_NAME="kafka"
VERSION="0.8.2.2"
BINARY_PACKAGE="kafka_2.10-${VERSION}"
BINARY_PACKAGE_URL="http://www.us.apache.org/dist/kafka/${VERSION}/${BINARY_PACKAGE}.tgz"
# SCALA_VERSION="2.10.0"
PACKAGE_SUFFIX="0"
DESCRIPTION="Apache Kafka is a distributed publish-subscribe messaging system."
URL="https://kafka.apache.org/"
ARCH="all"
SECTION="misc"
LICENSE="Apache Software License 2.0"
#SRC_PACKAGE="kafka-${VERSION}-src.tgz"
#DOWNLOAD_URL="http://www.us.apache.org/dist/kafka/${VERSION}/${SRC_PACKAGE}"
ORIG_DIR="$(pwd)"
# Put your name here, so you get contacted.
MAINTAINER="kafka-deb-packaging"

function cleanup() {
    rm -rf "${PKG_NAME}*.deb"
}

function download() {
  # download and upack binary version
  mkdir -p downloads
  pushd downloads
  wget -c ${BINARY_PACKAGE_URL}
  tar -xzf ${BINARY_PACKAGE}.tgz
  # strip out windows scripts from the archive
  rm -r ${BINARY_PACKAGE}/bin/windows
  popd
}

function bootstrap() {
    # if [[ ! -f "$SRC_PACKAGE" ]]; then
    #     wget ${DOWNLOAD_URL}
    # fi

    mkdir -p tmp
    pushd tmp
    rm -rf kafka

    mkdir -p kafka
    pushd kafka

    mkdir -p build/usr/lib/kafka     # for package
    mkdir -p build/usr/lib/kafka/bin
    mkdir -p build/usr/lib/kafka/libs
    # mkdir -p build/usr/lib/kafka/config - will be a symlink

    mkdir -p build/var/lib/kafka # for kafka messages storage

    # for configs
    # used a link in /opt/kafka/config to  build/etc/kafka
    mkdir -p build/etc/kafka # will be later linked from konfig
    mkdir -p build/etc/default

    mkdir -p build/etc/init.d    # for init script on debian
    mkdir -p build/var/log/kafka # for log files

    mkdir -p build/usr/share/doc/kafka/ # for docs

    # used /var/run/ to store kafka.pid
    popd
    popd
}

# # gets sources, builds project, forms the ../build, leaves to initial folder after
# function build_from_sources() {
#     tar zxf "${ORIG_DIR}/${SRC_PACKAGE}"
#     pushd "kafka-${VERSION}-src"
#
#     ./gradlew -PscalaVersion=${SCALA_VERSION} clean
#     ./gradlew -PscalaVersion=${SCALA_VERSION} jar
#
#     # KAFKA_HEAP_OPTS is reset to default.
#     # The patch should fix the ./logs creation though.
#     # TODO: fix and apply patch
#     # patch -p0 < "${ORIG_DIR}/kafka-bin.patch"
#
#     ## populate the /opt/kafka folder structure
#     # libs
#     cp -rp core/build/libs/* ../build/opt/kafka/libs
#     cp -rp core/build/dependant-libs-${SCALA_VERSION}/* ../build/opt/kafka/libs
#     # config
#     cp -rp config ../build/opt/kafka/
#     mv ../build/opt/kafka/config/log4j.properties ../build/opt/kafka/config/log4j.properties.orig
#     cp ${ORIG_DIR}/log4j.properties ../build/opt/kafka/config
#     # bin (we don't need windows binaries)
#     cp bin/*.sh ../build/opt/kafka/bin
#
#     # LICENSE and NOTICE
#     mv LICENSE ../build/opt/kafka/
#     mv NOTICE ../build/opt/kafka
#     popd
# }

function build_from_binary(){
  # assumed we are in tmp/kafka direcotry
    UNPACKED=downloads/${BINARY_PACKAGE}
    BUILD=tmp/kafka/build/
    cp -r $UNPACKED/bin $BUILD/usr/lib/kafka
    cp -r $UNPACKED/config/* $BUILD/etc/kafka
    cp -r $UNPACKED/libs $BUILD/usr/lib/kafka
    cp -r $UNPACKED/LICENSE $BUILD/usr/share/doc/kafka
    cp -r $UNPACKED/NOTICE $BUILD/usr/share/doc/kafka

    # we don't need windows binaries in deb package
    # symbolic link to configs is created in postinst script
}

function apply_configs(){

    pushd tmp
    pushd kafka
    cp "${ORIG_DIR}/etc/default/kafka" "build/etc/default/kafka"

    # Service
    cp "${ORIG_DIR}/etc/init.d/kafka" "build/etc/init.d/kafka"
    # TODO: Ubuntu option?
    #cp "${ORIG_DIR}/kafka-broker.upstart.conf" "build/etc/init/kafka-broker.conf"

    cp ${ORIG_DIR}/log4j.properties build/etc/kafka
    popd
    popd

    # symlink from /etc/kafka -> /opt/kafka/config is made in postinst
}

function mkdeb() {
  pushd tmp
  pushd kafka
  pushd build

  fpm -t deb \
    -n "$PKG_NAME" \
    -v "${VERSION}-${PACKAGE_SUFFIX}" \
    --description "$DESCRIPTION" \
    --url="$URL" \
    -a "$ARCH" \
    --category "$SECTION" \
    --vendor "" \
    --license "$LICENSE" \
    --before-install ${ORIG_DIR}/kafka.preinst \
    --after-install ${ORIG_DIR}/kafka.postinst \
    --after-remove ${ORIG_DIR}/kafka.postrm \
    -m "${MAINTAINER}" \
    --config-files /etc/default/kafka \
    --config-files /etc/init.d/kafka \
    --config-files /etc/kafka \
    --prefix=/ \
    -d "openjdk-7-jre" \
    -s dir \
    -- .
  mv kafka*.deb ${ORIG_DIR}

  popd
  popd
  popd
}

function sample_layout() {
  dpkg -c ${PKG_NAME}_${VERSION}-${PACKAGE_SUFFIX}_${ARCH}.deb > SAMPLE_LAYOUT.txt
}

function main() {
    cleanup
    download
    bootstrap
    #build_from_sources
    build_from_binary
    apply_configs
    mkdeb
    sample_layout
}

main
