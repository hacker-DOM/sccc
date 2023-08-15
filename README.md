# Installation

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default `~/.oh-my-zsh/custom/plugins`)
```zsh
git clone https://github.com/hacker-dom/zsh-sccd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-sccd
```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside ~/.zshrc):

```zsh
plugins=( 
    zsh-sccd
    # other plugins...
)
```

Keep in mind that plugins need to be added before oh-my-zsh.sh is sourced.


# Development log

- I wanted to reference `sccd.awk` with a relative link from the location of the (main) `zsh-sccd.plugin.zsh` file
    - this turned out to be quite difficult, and probably would be very error-prone, dealing with all the ways to source files is zsh (absolute vs relative path; same vs different directory; `source` vs `.`; different zsh options...),
    - so in the end I will just be using a path based on `$ZSH_CUSTOM`
