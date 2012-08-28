# cdd

A simple directory navigation utility for bash

* * *

## Introduction

`cdd` is designed to be an occasional replacement for `cd`, for times when you'd prefer to navigate your directory structure using vi cursor keys instead of spamming the tab key whilst trying ever-increasing subsets of that directory you'd like to enter.

## Installation

Drop `cdd.sh` somewhere onto your filesystem and add the following alias to your ~/.bash_profile: `alias cdd="path/to/cdd.sh"`

## Usage

The following stdin input options are available:

    h - Navigate to the parent directory
    j - Move the directory selection down
    k - Move the directory selection up
    l - Enter the selected directory
    ESC | q - Exit cdd without changing the current directory
    Enter - Exit cdd at the current directory