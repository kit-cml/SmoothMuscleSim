#!/bin/bash

# Use this to export the library path.
# Please change the directory according to your library's location.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/prog/sundials/sundials-5.7.0/lib:/usr/local/lib64:/usr/lib64
echo $LD_LIBRARY_PATH
export PATH=$PATH
echo $PATH

NUMBER_OF_CPU=1

# to grab cell_model value from parameter file (thanks, ChatGPT).
# grep "^user_name": looks for the line starting with user_name
# cut -d'=' -f2: gets the right-hand side of =
# sed 's/\/\/.*//': removes any inline comment starting with //
# xargs: trims leading and trailing whitespace
CELL_MODEL=$(grep "^cell_model" param.txt | cut -d'=' -f2 | cut -d'/' -f1 | cut -d'/' -f1 | sed 's/\/\/.*//' | xargs)
USER_NAME=$(grep "^user_name" param.txt | cut -d'=' -f2 | cut -d'/' -f1 | cut -d'/' -f1 | sed 's/\/\/.*//' | xargs)

RESULT_FOLDER="./results"


# choose the binary based on the value of cell_model
if [[ $CELL_MODEL == *"Tong"* ]]; then
  BINARY_FILE=../smoothmusclesim_Tong
#elif [[ $CELL_MODEL == *"ToR-ORd"* ]]; then
#  BINARY_FILE=../epsim_ToR-ORd
#elif [[ $CELL_MODEL == *"ToR-ORd-dynCl"* ]]; then
#  BINARY_FILE=../epsim_ToR-ORd-dynCl
#elif [[ $CELL_MODEL == *"ORd-static-Brugada-Dongguk"* ]]; then
#  BINARY_FILE=../epsim_ORd-static-Brugada-Dongguk
#elif [[ $CELL_MODEL == *"ORd-static"* ]]; then
#  BINARY_FILE=../epsim_ORd-static
else
  echo "The cell model ${CELL_MODEL} is not specified to any simulations!!"
  exit 1
fi

# Clear any old PID file
PIDFILE="mpiexec.pid"
rm -f "${PIDFILE}"

sh clear_workspace.sh
mkdir -p "${RESULT_FOLDER}"
echo "Run $CELL_MODEL model Smooth Muscle simulation with $NUMBER_OF_CPU cores."
( echo $$ > "${PIDFILE}"; exec mpiexec -np "${NUMBER_OF_CPU}" "${BINARY_FILE}" -input_deck param.txt >& "${RESULT_FOLDER}/logfile")
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "Simulation program got some problems!!! Exiting..."
  rm -rf "${PIDFILE}"
  exit 1
else
  echo "Simulation has finished! Check the logfile for more details."
  rm -rf "${PIDFILE}"
fi
