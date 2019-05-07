# donation.theopencloset.net #

[![Build Status](https://travis-ci.org/opencloset/donation.svg?branch=v0.5.11)](https://travis-ci.org/opencloset/donation)

## deps ##

    $ cpanm --installdeps .
    $ npm install
    $ bower install
    $ grunt

## run ##

    $ MOJO_CONFIG='donation.conf' morbo -v -l 'http://*:5000' ./script/donation

### upload clothes photo  ###

    $ MOJO_CONFIG='donation.conf' ./script/donation minion worker
