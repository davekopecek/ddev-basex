#ddev-generated
#!/bin/bash
echo "Current directory: $(pwd)"
echo "Looking for basex in: $(cd .. && pwd)/basex"

# Update BaseX paths
basex -c "set WEBPATH /srv/basex/webapp"
basex -c "set REPOPATH /srv/basex/repo"

# Sync project files if they exist
if [ -d "../basex/webapp" ]; then
  echo "Found webapp directory, syncing..."
  cp -r ../basex/webapp/* /srv/basex/webapp/
fi
if [ -d "../basex/repo" ]; then
  echo "Found repo directory, syncing..."
  cp -r ../basex/repo/* /srv/basex/repo/
fi