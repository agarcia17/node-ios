#!/usr/bin/env bash
set -e

ROOT=${PWD}
cd "$(dirname ${BASH_SOURCE})"
TOOLS_DIR="$PWD"

# should be node's source root
cd ../
PROJECT_DIR="$PWD"
NODE_OUTPUT_DIR="$PROJECT_DIR/out/Release"

NODE_IOS_FRAMEWORK_DIR="$TOOLS_DIR/ios-framework"
NODE_IOS_FRAMEWORK_PROJECT_FILE="$NODE_IOS_FRAMEWORK_DIR/NodeMobile.xcodeproj"
NODE_IOS_FRAMEWORK_BIN_DIR="$NODE_IOS_FRAMEWORK_DIR/bin"
NODE_IOS_FRAMEWORK_INTERMEDIATE_DIR="$NODE_IOS_FRAMEWORK_DIR/obj"
NODE_IOS_FRAMEWORK_OUTPUT_DIR="$PROJECT_DIR/out_ios"
XC_FRAMEWORK_ARGS=""
ARCHS_TO_COMPILE=("arm64")

NODE_OUTPUT_FILE_NAMES=(
    "libbrotli.a"
    "libcares.a"
    "libhistogram.a"
    "libllhttp.a"
    "libnghttp2.a"
    "libnode.a"
    "libopenssl.a"
    "libtorque_base.a"
    "libuv.a"
    "libuvwasi.a"
    "libv8_base_without_compiler.a"
    "libv8_compiler.a"
    "libv8_initializers.a"
    "libv8_libbase.a"
    "libv8_libplatform.a"
    "libv8_libsampler.a"
    "libv8_snapshot.a"
    "libv8_zlib.a"
    "libzlib.a"
)

build_node_for_arch() {
    local ARCH=$1
    export GYP_DEFINES="host_arch=${ARCH} host_os=mac target_arch=${ARCH} target_os=ios"

    # need to define -arch by ourself when we're cross compiling refer to xcode_emulation.py
    export CC="$(command -v cc) -arch ${ARCH}"
    export CXX="$(command -v c++) -arch ${ARCH}"
    export CC_host="$(command -v cc) -arch ${ARCH}"
    export CXX_host="$(command -v c++) -arch ${ARCH}"

    # prepare for node build
    ./configure \
        --dest-os=ios \
        --dest-cpu=${ARCH} \
        --with-intl=none \
        --cross-compiling \
        --enable-static \
        --openssl-no-asm \
        --v8-options=--jitless \
        --without-node-code-cache \
        --without-node-snapshot

    # perform node build
    make -j$(getconf _NPROCESSORS_ONLN)

    # clean node ios framework intermediate directory
    rm -rf "$NODE_IOS_FRAMEWORK_INTERMEDIATE_DIR/$ARCH"
    mkdir -p "$NODE_IOS_FRAMEWORK_INTERMEDIATE_DIR/$ARCH"

    # copy node's build output files to node ios framework intermediate directory
    for i in "${NODE_OUTPUT_FILE_NAMES[@]}"; do
        cp "$NODE_OUTPUT_DIR/$i" "$NODE_IOS_FRAMEWORK_INTERMEDIATE_DIR/$ARCH/$i"
    done
}

build_node_ios_framework_for_arch() {
    local ARCH=$1
    local SDK_TYPE="iphoneos"

    if [ "$ARCH" = "x86_64" ]; then
        SDK_TYPE="iphonesimulator"
    fi

    # clean node ios framework bin directory
    rm -rf "$NODE_IOS_FRAMEWORK_BIN_DIR"
    mkdir -p "$NODE_IOS_FRAMEWORK_BIN_DIR"

    # copy the node build files of the specified arch to node ios framework bin directory
    cp "$NODE_IOS_FRAMEWORK_INTERMEDIATE_DIR/$ARCH"/*.a "$NODE_IOS_FRAMEWORK_BIN_DIR/"
    # perform actual build of node ios framework xcode project
    xcodebuild build -project "$NODE_IOS_FRAMEWORK_PROJECT_FILE" -target "NodeMobile" -configuration "Release" -arch "$ARCH" -sdk "$SDK_TYPE" SYMROOT="$NODE_IOS_FRAMEWORK_OUTPUT_DIR"
    XC_FRAMEWORK_ARGS+=" -framework \"$NODE_IOS_FRAMEWORK_OUTPUT_DIR/Release-$SDK_TYPE/NodeMobile.framework\""
}

for i in "${ARCHS_TO_COMPILE[@]}"; do
    echo "Started compiling Node.Js for '$i' arch"
    make clean
    build_node_for_arch $i
    echo "Finished compiling Node.Js for '$i' arch"
done

# clean node ios framework output directory
rm -rf "$NODE_IOS_FRAMEWORK_OUTPUT_DIR"
mkdir -p "$NODE_IOS_FRAMEWORK_OUTPUT_DIR"

# don't override xcodebuild's CC
unset CC CXX CC_host CXX_host

for i in "${ARCHS_TO_COMPILE[@]}"; do
    echo "Started building Node iOS Framework for '$i' arch"
    build_node_ios_framework_for_arch $i
    echo "Finished building Node iOS Framework for '$i' arch"
done

if [[ -n "$XC_FRAMEWORK_ARGS" ]]
then
  # create a .xcframework
  eval "xcodebuild -create-xcframework${XC_FRAMEWORK_ARGS} -output \"${NODE_IOS_FRAMEWORK_OUTPUT_DIR}/NodeMobile.xcframework\""
fi

echo "Frameworks built to $NODE_IOS_FRAMEWORK_OUTPUT_DIR"

cd "$ROOT"
