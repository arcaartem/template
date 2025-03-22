# Pure Shell Template Engine

A lightweight, dependency-free template engine written in POSIX compliant shell script. It supports variable substitution, conditionals, subshell commands, and file inclusion.

## Features

- No external dependencies (works with sh, bash, zsh)
- Variable substitution with `${VAR}` syntax
- Conditional blocks with `@if`, `@else`, and `@endif`
- File inclusion with `@include`
- Subshell command execution with `$(command)`
- POSIX-compliant
- Recursive template processing (included files are also processed as templates)

## Installation

Simply download the script and make it executable:

```bash
chmod +x template.sh
```

## Development Setup

### Prerequisites

- A POSIX-compliant shell (sh, bash, or zsh)
- Git (for cloning the repository)

### Setting Up the Development Environment

1. Clone the repository:
```bash
git clone git@github.com:arcaartem/template.git
cd template
```

2. Make the template script executable:
```bash
chmod +x src/template.sh
```

3. Install BATS (Bash Automated Testing System - see documentation for more up to date installation instructions):
```bash
# On macOS with Homebrew:
brew install bats

# On Ubuntu/Debian:
sudo apt-get install bats

# On Fedora:
sudo dnf install bats
```

### Running Tests

The project uses BATS for testing. To run the test suite:

```bash
bats test/template.bats
```

## Usage

```bash
./template.sh template_file [var1=value1 var2=value2 ...]
```

### Basic Example

template.txt:
```text
Hello, ${NAME}!
Today is $(date)
```

Run:
```bash
./template.sh template.txt NAME="John"
```

Output: 
```
Hello, John!
Today is Wed Mar 13 15:30:45 EDT 2024
```

### Variable Substitution

Variables can be passed as arguments and used in templates with `${VAR}` syntax:

```text
User: ${USER_NAME}
Email: ${EMAIL}
Role: ${ROLE}
```

Run:
```bash
./template.sh template.txt USER_NAME="Alice" EMAIL="alice@example.com" ROLE="admin"
```

### Conditional Blocks

Supports `@if`, `@else`, and `@endif` for conditional content:

```text
@if [ "${USER_TYPE}" = "admin" ]
Welcome, Administrator!
You have full access.
@else
Welcome, User!
You have limited access.
@endif

@if [ -n "${CUSTOM_MESSAGE}" ]
Message: ${CUSTOM_MESSAGE}
@endif
```

### File Inclusion

Include other template files using `@include`:

main.template:
```text
Header:
@include header.template

Content:
${CONTENT}

Footer:
@include footer.template
```

header.template:
```text
=================
${SITE_NAME}
=================
```

Run:
```bash
./template.sh main.template SITE_NAME="My Site" CONTENT="Page content here"
```

### Subshell Commands

Execute shell commands within templates using `$(command)`:

```text
System Information:
------------------
Hostname: $(hostname)
User: $(whoami)
Date: $(date)
Uptime: $(uptime)
```

## Advanced Examples

### Nested Conditionals

```text
@if [ "${ENVIRONMENT}" = "production" ]
    Server: production.example.com
    @if [ "${DEPLOY_TYPE}" = "canary" ]
    Deploy Type: Canary Release
    @else
    Deploy Type: Full Release
    @endif
@else
    Server: staging.example.com
    Environment: ${ENVIRONMENT}
@endif
```

### Dynamic Includes

```text
@if [ "${THEME}" = "dark" ]
@include themes/dark.template
@else
@include themes/light.template
@endif
```

### Configuration Template

config.template:
```text
# Generated configuration
# Date: $(date)
# Author: ${AUTHOR}

[server]
host = ${SERVER_HOST}
port = ${SERVER_PORT}

@if [ "${ENABLE_SSL}" = "yes" ]
[ssl]
certificate = ${SSL_CERT}
key = ${SSL_KEY}
@endif

[database]
@include db/${DB_TYPE}.template
```

Run:
```bash
./template.sh config.template \
    AUTHOR="DevOps Team" \
    SERVER_HOST="localhost" \
    SERVER_PORT="8080" \
    ENABLE_SSL="yes" \
    SSL_CERT="/path/to/cert" \
    SSL_KEY="/path/to/key" \
    DB_TYPE="postgres"
```

## Security Considerations

- The script uses `eval` for variable substitution and subshell execution
- Be careful when processing templates from untrusted sources
- Variables and included files should be validated before processing

## Limitations

- No nested variable substitution (e.g., `${${VAR}}`)
- No loop constructs
- No complex expressions in conditions (only shell test expressions)

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - feel free to use and modify as needed.