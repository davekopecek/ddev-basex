# ddev-basex

## What is ddev-basex?

This repository provides a [BaseX](https://basex.org) add-on for DDEV. BaseX is a robust XML database engine and XQuery processor.

## Installation

Until this add-on is officially released, you can install it directly from the repository:



```bash
ddev add-on get davekopecek/ddev-basex
ddev restart
```

## Configuration

The BaseX server will be available at:
- Web interface: `http://[project-name].ddev.site:8984`
- Default admin credentials: username `admin` with no password

To set an admin password, you can run:
```bash
ddev exec -s basex 'echo "your-password" | basex -cPASSWORD'
ddev restart
```

## Directories

The add-on creates three directories in your project's `.ddev/basex` folder:
- `data/`: Persists BaseX data
- `webapp/`: For BaseX web applications
- `repo/`: For BaseX package repository

## Features

- Based on the `quodatum/basexhttp` image
- Supports multiple architectures (amd64, arm64, arm/v7)
- Includes Saxon-HE for XSLT 3.0 support
- Includes XMLresolver

**Contributed and maintained by [@yourusername](https://github.com/yourusername)** 