#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

export JAVA_OPTS="
-Djava.awt.headless=true
-Dsun.java2d.xrender=false
-Dsun.java2d.opengl=false
"

NETLOGO_HOME="/home/m-saito/NetLogo6.3.0"

MODEL_PATH="$BASE_DIR/netlogo/HrSharing_test_pyextention-20260505.nlogo"

OUTPUT_PATH="$BASE_DIR/results/results.csv"

"$NETLOGO_HOME/netlogo-headless.sh" \
  --model "$MODEL_PATH" \
  --experiment "experiment202602_Z" \
  --threads 1 \
  --table "$OUTPUT_PATH"