check_port() {
  echo "# Checking port 9984..." >&3
  echo "# netstat output:" >&3
  netstat -an | grep 9984 >&3 2>&1 || echo "# Port 9984 is free (netstat)" >&3
  echo "# docker output:" >&3
  docker ps | grep 9984 >&3 2>&1 || echo "# No docker containers using port 9984" >&3
}

setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-basex
  mkdir -p $TESTDIR
  export PROJNAME=test-basex
  export DDEV_NON_INTERACTIVE=true
  
  # Debug: Check port status before setup
  check_port
  
  # Clean up any existing DDEV projects and ensure all services are stopped
  ddev poweroff >/dev/null 2>&1 || true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  
  # In CI, ensure DDEV is configured properly
  if [ -n "${CI:-}" ]; then
    # New way to configure router for CI
    ddev config global --web-environment="DDEV_ROUTER_BIND_ALL_INTERFACES=true"
    sleep 5
  fi
  
  cd "${TESTDIR}"
  
  # Configure project with environment-specific settings
  ddev config --project-name=${PROJNAME}
  
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
  
  # Stop all DDEV projects and remove the test project
  ddev poweroff >/dev/null 2>&1 || true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  
  # Clean up BaseX data and volumes
  docker volume rm -f $(docker volume ls -q | grep ${PROJNAME}) >/dev/null 2>&1 || true
  
  # Remove test directory
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
  
  # Wait for TIME_WAIT to clear (check every 2 seconds for up to 30 seconds)
  for i in {1..15}; do
    if ! netstat -an | grep 9984 | grep TIME_WAIT > /dev/null; then
      break
    fi
    echo "# Waiting for port 9984 TIME_WAIT to clear (attempt $i)..." >&3
    sleep 2
  done
  
  # Debug: Check port status after cleanup
  check_port
}

@test "install from directory" {
  cd ${TESTDIR}
  
  # Install the add-on
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
  cd ${TESTDIR}
  
  # Install the add-on
  echo "# Installing add-on from GitHub..." >&3
  ddev add-on get davekopecek/ddev-basex
  
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