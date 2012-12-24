zshtools
========

Some helpful zsh related utilities for file listing and querying and more too.  

I've been using zsh for a while, but only lately begun diving into it. I started by making a script named `list` which gives me various kinds of listings which i can select on a keypress.     

e.g. after invoking list, on pressing "t" one gets today's modified files, or on pressing "d", the directories in the current dir. 

I then made a slightly more complex list query tool (again single key presses to make it fast) so I can query fies based on modification times and sizes or both. Its called `listquery`.  

listquery also prints out the command to be executed so you can learn the various zsh globbing options.

That led me to write a directory lister and chooser which is hotkey based. After a couple of different iterations, I made zfm (https://github.com/rkumar/zfm). Check out tools.zsh and modify it to your need. It should be here but it relies on common files that are in zfm. I am not sure how to maintain a common dependency.  

I am running these scripts on zsh v5.0.x (homebrew on OSX Mountain Lion, in iTerm and tmux).

Installation
------------

Place these in the path, preferably in $HOME/bin or you may have to set ZFM_DIR to where you've placed them, so they can source common files correctly.

Preferably, alias list and listquery to something short (in your ~/.zshrc). e.g.

    alias lq='listquery'
