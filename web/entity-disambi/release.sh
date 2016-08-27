#!/bin/sh

FURY_URL=https://pypi.fury.io/${FURY_SECRET_TOKEN}/studioousia/
VERSION=`python setup.py --version`

python setup.py sdist
curl -F package=@dist/entity-disambi-$VERSION.tar.gz $FURY_URL
