# donation.theopencloset.net #

## deps ##

    $ cpanm --installdeps .
    $ npm install
    $ bower install
    $ grunt

## run ##

    $ MOJO_CONFIG='donation.conf' morbo -v -l 'http://*:5000' ./script/donation

### upload clothes photo  ###

    $ MOJO_CONFIG='donation.conf' ./script/donation minion worker
