#!/bin/zsh

find . -name '*.gyb' |                                               \
    while read file; do                                              \
        ./gyb --line-directive '' -o "${file%.gyb}" "$file"; \
    done