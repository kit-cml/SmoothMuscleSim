#!/bin/bash

PIDFILE="mpiexec.pid"

if [[ ! -f "${PIDFILE}" ]]; then
  echo "No PID file found. Is the simulation running?"
  exit 1
fi

MPI_PID=$(cat "${PIDFILE}")
echo "Killing mpiexec process tree starting from PID ${MPI_PID}..."

# Recursive kill function
kill_tree() {
  local _pid=$1
  local _sig=${2:-TERM}
  for _child in $(pgrep -P "$_pid"); do
    kill_tree "$_child" "$_sig"
  done
  kill -s "$_sig" "$_pid" 2>/dev/null
}

kill_tree "${MPI_PID}" SIGKILL

# Optional: clean up the PID file
rm -f "${PIDFILE}"

echo "mpiexec and its child processes have been terminated."
