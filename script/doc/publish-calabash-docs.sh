#!/usr/bin/env bash

SERVER=calabashapi.xamarin.com

echo "INFO: cleaning local documentation artifacts."
rm -rf doc.tar

cd calabash-cucumber

echo "INFO: generate docs with yard."
bundle exec rake yard

echo "INFO: clearing artifacts in $SERVER:~/."
ssh $SERVER 'rm -rf doc.tar; rm -rf doc'

echo "INFO: creating a tarball to upload."
tar -cf doc.tar doc

echo "INFO: copying tarball to $SERVER"
scp doc.tar $SERVER:~/

echo "INFO: expanding $SERVER:~/doc.tar"
ssh $SERVER 'tar -xf doc.tar'

echo "INFO: deleting calabash docs."
ssh $SERVER 'sudo rm -rf /srv/www/calabashapi.xamarin.com/ios'

echo "INFO: staging new calabash docs."
ssh $SERVER 'sudo mv doc /srv/www/calabashapi.xamarin.com/ios'

echo "INFO: cleaning remote artifacts."
ssh $SERVER 'rm -rf doc.tar; rm -rf doc'

echo "INFO: cleaning local artifacts."
rm -rf doc.tar

echo "INFO: done!"

