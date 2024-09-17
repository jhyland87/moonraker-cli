


# Install
```bash
$ git clone https://github.com/jhyland87/moonraker-cli.git
$ ./moonraker-cli/install
```

This should try to create a symlink to the `./moonraker-cli/moonraker` file at `/usr/local/bin/moonraker`. 

# Usage
`moonraker <subcommand> <arguments>`

# Project file structure
The main `moonraker` file is in the root. Each command is a .sh file inside the commands folder.

```
# Command file layout
moonraker-cli
├── moonraker
└── commands
  ├── bed.sh
  ├── example.sh
  ├── file.sh
  ├── help.sh
  ├── history.sh
  ├── job.sh
  ├── logs.sh
  ├── macro.sh
  ├── printer.sh
  ├── service.sh
  ├── status.sh
  ├── watch.sh
  └── webcam.sh
```

To execute a command: _moonraker_ __command__ _[args]_
Examples
```bash
# Show high level help
moonraker help 

# Show printer command help
moonraker printer help

# Show printer info
moonraker printer info

# Test printer service availability
moonraker printer test
```