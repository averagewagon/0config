# TODO

- Obsidian config (maybe add .obsidian settings sync?)
  - date format for daily notes
  - daily template
  - ctrl-d for daily note opening
  - ctrl-m for readable line length toggle
  - line numbers
  - turn off "indent using tabs"
  - folder for new attachments
- Switch off GitHub (for Codeberg?)
- RSS feed reader which syncs between phone and computer
- Update `work.nix` to read SSH key paths from a `workMachine.hostname` option
  - Add option `workMachine.hostname` (lib.types.str) to the module
  - Replace `~/.ssh/personal_key` with `~/.ssh/${config.workMachine.hostname}-personal-key`
  - Replace `~/.ssh/work_key` with `~/.ssh/${config.workMachine.hostname}-work-key`
  - Set the value in the `work` flake target's module list:
    `{ workMachine.hostname = "wk-fenugreek"; }`
  - On the work machine: rename `~/.ssh/{personal,work}_key{,.pub}` to the new paths and re-run
    `ssh-add`
- Fish: show a warning when no SSH key is loaded into the agent
- Name machines with type - e.g. laptop_saffron instead of saffron
- Add symlinking 0config and prepping zed workspace w/ docs as helper step
- Add man pages for tons of things
- Make a .editorconfig with my general defaults
- Script to set all photo "last modified" dates in a folder to whatever's in the metadata
- Get an image viewer I like
- Set up Actual server
- Investigate https://flathub.org/en/apps/io.github.aganzha.Stage
- Update Home Manager major version
- Home Assistant
