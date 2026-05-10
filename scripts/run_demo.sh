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

mkdir -p "$BASE_DIR/results"

"$NETLOGO_HOME/netlogo-headless.sh" \
  --threads 1 \
  --model "$MODEL_PATH" \
  --experiment "experiment202602_Z" \
  --table "$OUTPUT_PATH"


# #!/bin/bash

# export JAVA_OPTS="
# -Djava.awt.headless=true
# -Dsun.java2d.xrender=false
# -Dsun.java2d.opengl=false
# "

# NETLOGO_HOME="/home/b17z6ms/NetLogo6.3.0"
# MODEL_PATH="/home/b17z6ms/src/logo/HrSharing_test_pyextention-20260313.nlogo"

# "$NETLOGO_HOME/netlogo-headless.sh" \
#   --model "$MODEL_PATH" \
#   --experiment "experiment202602_Z" \
#   --table "/home/b17z6ms/src/logo/results.csv"


# ###################

# # ==== 実行 ====
# "$NETLOGO_HOME/netlogo-headless.sh" \
#   --model "$MODEL_PATH" \
#   --setup-file /dev/null \
#   --experiment "pytest" \
#   --table results.csv \
#   --threads 1 \
#   --exit






# "$NETLOGO_HOME/netlogo-headless.sh" \
#   --model "$MODEL_PATH" \
#   --commands "setup repeat 3 [ call-python ]"


# # NetLogo Headless モードで実行
# "$NETLOGO_HOME/netlogo-headless.sh" \
#   --model "$MODEL_PATH" \
#   --setup-file <(echo "setup") \
#   --run-file <(echo "call-python")










# "$NETLOGO_HOME/netlogo-headless.sh" \
#   --model "$MODEL_PATH" \
#   --commands "setup repeat 1 [ call-python ]"






# #!/bin/bash

# NETLOGO_HOME="/home/b17z6ms/NetLogo_7.0.1"
# MODEL_PATH="/home/b17z6ms/src/logo/test_py_extension.nlogo"




# "$NETLOGO_HOME/netlogo-headless.sh" \
#   --model "$MODEL_PATH" \
#   --experiment "default" \
#   --setup-file <(echo "setup") \
#   --run-file <(echo "call-python")



# # ./NetLogo_Console --headless \
# #   --model "$MODEL_PATH" \
# #   --setup-file ~/my-wsp-setups.xml \
# #   --experiment "My WSP Exploration"