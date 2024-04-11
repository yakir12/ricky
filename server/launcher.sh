#!/bin/sh
cd $HOME/ricky/server
julia --project=$HOME/ricky/server/Project.toml --threads=4 $HOME/ricky/server/server.jl &
