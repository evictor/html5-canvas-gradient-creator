#!/usr/bin/bash
SCRIPT_PATH=$0
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
BUILD_DIR=$SCRIPT_DIR"/build/"
SRC_DIR=$SCRIPT_DIR"/src/"
coffee -o $BUILD_DIR -cw $SRC_DIR
