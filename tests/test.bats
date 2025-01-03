setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-basex
  mkdir -p $TESTDIR
  export PROJNAME=test-basex
  export DDEV_NON_INTERACTIVE=true
  
  # Clean up any existing DDEV projects
  ddev poweroff >/dev/null 2>&1 || true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

health_checks() {
  # Wait for BaseX to be ready
  sleep 10
  
  echo "# Testing BaseX service..." >&3
  full_output=$(ddev exec -s basex "basex -c 'HELP'")
  response=$(echo "$full_output" | grep -o "EXIT")
  
  if [ "$response" != "EXIT" ]; then
    echo "# BaseX service not responding correctly" >&3
    echo "# Checking if BaseX container is running..." >&3
    ddev exec "docker ps | grep basex" >&3
    echo "# Checking BaseX logs..." >&3
    ddev logs -s basex >&3
    return 1
  fi
  echo "# ✓ BaseX service test passed" >&3
  
  echo "# Testing internal interface..." >&3
  response=$(ddev exec "curl -s basex:8080")
  if ! grep -q "BaseX" <<< "$response"; then
    echo "# BaseX internal interface not responding" >&3
    return 1
  fi
  echo "# ✓ Internal interface test passed" >&3
  
  echo "# Testing external interface..." >&3
  response=$(curl -s https://${PROJNAME}.ddev.site:9984)
  if ! grep -q "BaseX" <<< "$response"; then
    echo "# BaseX external interface not responding" >&3
    return 1
  fi
  echo "# ✓ External interface test passed" >&3
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  
  # Clean up BaseX data
  ddev exec -s basex "rm -rf /srv/basex/data/*" >/dev/null 2>&1 || true
  
  # Remove project and volumes
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  docker volume rm -f $(docker volume ls -q | grep ${PROJNAME}) >/dev/null 2>&1 || true
  
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  
  # First configure and start DDEV
  echo "# Configuring DDEV project..." >&3
  ddev config --project-name=${PROJNAME}
  ddev start
  
  # Then install the add-on
  echo "# Installing add-on..." >&3
  ddev add-on get ${DIR}
  
  # Restart after add-on installation
  echo "# Restarting DDEV..." >&3
  ddev restart
  
  # Wait for BaseX to be ready
  echo "# Waiting for BaseX to be ready..." >&3
  sleep 10
  
  # Now run health checks
  echo "# Running health checks..." >&3
  health_checks
}

# @test "install from release" {
#   set -eu -o pipefail
#   cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
#   echo "# ddev add-on get ddev/ddev-lucee with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
#   ddev add-on get ddev/ddev-lucee
#   ddev restart >/dev/null
#   health_checks
# }