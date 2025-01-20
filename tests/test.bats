setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-basex
  mkdir -p $TESTDIR
  export PROJNAME=test-basex
  export DDEV_NON_INTERACTIVE=true
  
  # Clean up any existing processes that might be using our ports
  if [ -n "${CI:-}" ]; then
    sudo lsof -ti:9984 | xargs -r sudo kill -9
    ddev config global --router-bind-all-interfaces
  fi
  
  # Clean up any existing DDEV projects
  ddev poweroff >/dev/null 2>&1 || true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  
  cd "${TESTDIR}"
  
  # Configure project with environment-specific settings
  if [ -n "${CI:-}" ]; then
    ddev config --project-name=${PROJNAME} --router-bind-all-interfaces
  else
    ddev config --project-name=${PROJNAME}
  fi
  
  ddev start -y >/dev/null
}

health_checks() {
  # Wait longer in CI environment
  if [ -n "${CI:-}" ]; then
    sleep 30  # Give more time for services to stabilize in CI
  else
    sleep 10
  fi
  
  # Get the correct hostname based on environment
  if [ -n "${CI:-}" ]; then
    HOST="127.0.0.1"
  else
    HOST="${PROJNAME}.ddev.site"
  fi
  
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
  if [ -n "${CI:-}" ]; then
    response=$(curl -s http://127.0.0.1:9984)
  else
    response=$(curl -s https://${PROJNAME}.ddev.site:9984)
  fi
  
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

@test "install from GitHub repository" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# Testing installation from GitHub repository..." >&3
  
  # Configure and start DDEV
  ddev config --project-name=${PROJNAME}
  ddev start
  
  # Install from your GitHub repository - using correct repository name
  echo "# Installing add-on from GitHub..." >&3
  ddev add-on get davekopecek/ddev-basex
  
  # Restart after installation
  echo "# Restarting DDEV..." >&3
  ddev restart
  
  # Run health checks
  echo "# Running health checks..." >&3
  health_checks
}

# TODO: Uncomment and update once this becomes an official DDEV add-on
# @test "install from release" {
#   set -eu -o pipefail
#   cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
#   echo "# Testing installation from release..." >&3
#   
#   # Configure and start DDEV
#   ddev config --project-name=${PROJNAME}
#   ddev start
#   
#   # Install from GitHub release
#   echo "# Installing add-on from release..." >&3
#   ddev add-on get ddev/ddev-basex
#   
#   # Restart after installation
#   echo "# Restarting DDEV..." >&3
#   ddev restart
#   
#   # Run health checks
#   echo "# Running health checks..." >&3
#   health_checks
# }