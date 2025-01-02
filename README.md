# ddev-basex

## What is ddev-basex?

This repository provides a [BaseX](https://basex.org) add-on for DDEV. BaseX is a robust XML database engine and XQuery processor.

## Features

- Based on the `quodatum/basexhttp` image
- Supports multiple architectures (amd64, arm64, arm/v7)
- Includes Saxon-HE for XSLT 3.0 support
- Includes XMLresolver
- Includes BaseX Web Application Server

## Installation

Until this add-on is officially released, you can install it directly from the repository:

```bash
ddev add-on get davekopecek/ddev-basex
ddev restart
```

## Access

The BaseX server is available at:
- Web interface: `http://[project-name].ddev.site:9984`
- HTTPS interface: `https://[project-name].ddev.site:9984`
- Default admin credentials: username `admin` with password `admin`

Note: The port (9984) is required as the standard HTTP/HTTPS ports (80/443) are used by the main web container.

## Configuration

To set a new admin password:
```bash
# Replace my-new-password with your desired password
ddev exec -s basex 'echo "my-new-password" | basex -cPASSWORD'
ddev restart
```

## Storage

The add-on uses a combination of Docker volumes and project directories:

### Docker Volume (Persistent Data)
- `basex-data`: Persists BaseX database data
- `basex-webapp`: For BaseX web applications
- `basex-repo`: For BaseX package repository

### Project Directories (Version Controlled)
- `basex/webapp/`: For BaseX web applications
- `basex/repo/`: For BaseX package repository

Store your BaseX applications and repositories in the project directories to maintain them in version control with your project.

## Development Workflow

Store your BaseX applications and repositories in your project's `basex` directory:
```
project-root/
├── basex/
│   ├── webapp/  # Store web applications here
│   └── repo/    # Store repositories here
```

Changes in these directories will be synced to the BaseX container on startup.

## Example Applications

### Simple REST API

Create a new file `basex/webapp/hello.xqm`:
```xquery
module namespace page = 'http://basex.org/examples/web-page';

declare %rest:path("hello")
        %rest:GET
function page:hello() {
  <response>
    <message>Hello from BaseX!</message>
    <time>{current-dateTime()}</time>
  </response>
};

declare %rest:path("hello/{$name}")
        %rest:GET
function page:hello-name($name) {
  <response>
    <message>Hello, {$name}!</message>
    <time>{current-dateTime()}</time>
  </response>
};
```

Access your API at:
- `http://[project-name].ddev.site:9984/hello`
- `http://[project-name].ddev.site:9984/hello/YourName`

### Utility Module

Create a new file `basex/repo/util.xqm`:
```xquery
module namespace util = 'http://example.org/util';

declare function util:greet($name as xs:string) as element(greeting) {
  <greeting>
    <to>{$name}</to>
    <message>Welcome to BaseX!</message>
    <timestamp>{current-dateTime()}</timestamp>
  </greeting>
};

declare function util:format-date($date as xs:dateTime) as xs:string {
  format-dateTime($date, "[D01] [MNn] [Y0001] at [H01]:[m01]:[s01]")
};
```

## Working with Databases

### Creating a Database
```bash
# Create a database from an XML file
ddev exec -s basex "basex -c 'CREATE DB mydb /path/to/data.xml'"

# Create an empty database
ddev exec -s basex "basex -c 'CREATE DB mydb'"
```

### Querying a Database
```bash
# Run a simple query
ddev exec -s basex "basex -c 'XQUERY db:open(\"mydb\")//title'"

# Run a query from a file
ddev exec -s basex "basex -i /path/to/query.xq"

# Interactive query session
ddev ssh -s basex
basex
> OPEN mydb
> XQUERY //title
> EXIT
```

## Accessing the Container

To SSH into the BaseX container:
```bash
ddev ssh -s basex
```

To run a command in the container without SSH:
```bash
ddev exec -s basex "your-command-here"
```

## Logs

To view BaseX logs:
```bash
# View BaseX logs
ddev logs -s basex

# Follow BaseX logs in real-time
ddev logs -s basex -f
```

**Contributed and maintained by [@davekopecek](https://github.com/yourusername)**


