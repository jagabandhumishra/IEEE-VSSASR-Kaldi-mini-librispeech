#!/usr/bin/env bash



remove_archive=false

if [ "$1" == --remove-archive ]; then
  remove_archive=true
  shift
fi
# check the number of arguments passed
if [ $# -ne 2 ]; then
  echo "Usage: $0 [--remove-archive] <data-base> <url-base> <corpus-part>"
  echo "e.g.: $0 /export/a05/dgalvez/ www.openslr.org/resources/31 dev-clean-2"
  echo "With --remove-archive it will remove the archive after successfully un-tarring it."
  echo "<corpus-part> can be one of: dev-clean-2, test-clean-5, dev-other, test-other,"
  echo "          train-clean-100, train-clean-360, train-other-500."
fi


## assigning the arguments
data=$1

part=$2

## check the existance of path
if [ ! -d "$data" ]; then
  echo "$0: no such directory $data"
  exit 1;
fi



cd $data

if ! tar -xvzf $part.tar.gz; then
  echo "$0: error un-tarring archive $data/$part.tar.gz"
  exit 1;
fi

#touch $data/LibriSpeech/$part/.complete

echo "$0: Successfully downloaded and un-tarred $data/$part.tar.gz"

if $remove_archive; then
  echo "$0: removing $data/$part.tar.gz file since --remove-archive option was supplied."
  rm $data/$part.tar.gz
fi
