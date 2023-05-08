#!/bin/bash

mkdir -p out

ruby main.rb code/01_meteors.txt > out/01_meteors.txt
ruby main.rb code/02_rats.txt > out/02_rats.txt
ruby main.rb code/03_bruteforce.txt > out/03_bruteforce.txt
ruby main.rb code/04_mod4.txt > out/04_mod4.txt
ruby main.rb code/05_maze.txt > out/05_maze.txt