#!/bin/bash
#
# Copyright 2023 shadow3aaa@gitbub.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
init_package() {
	cd $SHDIR
	rm -rf $TEMPDIR
	mkdir -p $TEMPDIR
	cp -rf module/* $TEMPDIR/
	mkdir -p $TEMPDIR/zygisk
}

build() {
	local TEMPDIR=$SHDIR/output/.temp
	local NOARG=true
	local HELP=false
	local CLEAN=false
	local DEBUG_BUILD=false
	local RELEASE_BUILD=false
	local VERBOSE=false

	if [ "$TERMUX_VERSION" = "" ]; then
		RR='cargo ndk -p 31 -t arm64-v8a'

		if [ "$ANDROID_NDK_HOME" = "" ]; then
			echo Missing ANDROID_NDK_HOME >&2
			exit 1
		else
			dir="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
			STRIP="$dir/llvm-strip"
		fi
	else
		RR=cargo
		STRIP=strip
	fi

	for arg in $@; do
		case $arg in
		clean | --clean)
			CLEAN=true
			;;
		r | -r | release | --release)
			RELEASE_BUILD=true
			;;
		d | -d | debug | --debug)
			DEBUG_BUILD=true
			;;
		-h | h | help | --help)
			HELP=true
			;;
		v | -v | verbose | --verbose)
			VERBOSE=true
			;;
		*)
			echo Illegal parameter: $arg >&2
			echo Try \'./make.sh build --help\' >&2
			exit 1
			;;
		esac

		NOARG=false
	done

	set -e
	chmod +x zygisk/build.sh

	if $HELP || $NOARG; then
		echo "./build.sh:
    --release / release / -r / r:
        release build
    --debug / debug / -d / d:
        debug build
    --verbose / verbose / -v / v:
        print details of build"

		exit
	elif $CLEAN; then
		rm -rf output
		cargo clean

		zygisk/build.sh --clean

		exit
	fi

	if $DEBUG_BUILD; then
		if $VERBOSE; then
			$RR build --target aarch64-linux-android -v
			zygisk/build.sh --debug -v
		else
			$RR build --target aarch64-linux-android
			zygisk/build.sh --debug
		fi

		init_package
		cp -f target/aarch64-linux-android/debug/fas-rs $TEMPDIR/fas-rs
		cp -f zygisk/output/arm64-v8a.so $TEMPDIR/zygisk/arm64-v8a.so

		cd $TEMPDIR
		zip -9 -rq "../fas-rs(debug).zip" .

		echo "Module Packaged: output/fas-rs(debug).zip"
	fi

	if $RELEASE_BUILD; then
		if $VERBOSE; then
			$RR build --release --target aarch64-linux-android -v
			zygisk/build.sh --release -v
		else
			$RR build --release --target aarch64-linux-android
			zygisk/build.sh --release
		fi

		init_package
		cp -f target/aarch64-linux-android/release/fas-rs $TEMPDIR/fas-rs
		cp -f zygisk/output/arm64-v8a.so $TEMPDIR/zygisk/arm64-v8a.so

		$STRIP $TEMPDIR/fas-rs
		$STRIP $TEMPDIR/zygisk/arm64-v8a.so

		cd $TEMPDIR
		zip -9 -rq "../fas-rs(release).zip" .

		echo "Module Packaged: output/fas-rs(release).zip"
	fi

}
