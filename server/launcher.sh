#!/bin/sh
cd $HOME/ricky/server
$HOME/julia/julia --project=$HOME/ricky/server/Project.toml --threads=4 $HOME/ricky/server/server.jl &
