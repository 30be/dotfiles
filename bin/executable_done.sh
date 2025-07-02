#!/bin/bash
task $(task | awk 'NR==4 {print $1}') done
task $(task | awk 'NR==4 {print $1}') start
timew tag work
