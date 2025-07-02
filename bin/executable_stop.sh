#!/bin/bash
task $(task | awk 'NR==4 {print $1}') stop
timew stop
timew stop
timew start rest
