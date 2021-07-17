#!/usr/bin/env bash

# Jagabandhu Mishra, IIT Dharwad, IEEE VSSASR

if [ $# -ne "2" ]; then
  echo "Usage: $0 <base-url> <download_dir> <local?"
  echo "e.g.: $0 http://www.openslr.org/resources/11 ./corpus/ data/local/lm"
  exit 1
fi


dst_dir=$1
local_dir=$2

###

mkdir -p $dst_dir $local_dir


dst_dir=$(readlink -f $dst_dir)
ln -sf $dst_dir/3-gram.pruned.1e-7.arpa.gz $local_dir/lm_tgmed.arpa.gz
ln -sf $dst_dir/3-gram.pruned.3e-7.arpa.gz $local_dir/lm_tgsmall.arpa.gz
ln -sf $dst_dir/3-gram.arpa.gz $local_dir/lm_tglarge.arpa.gz
ln -sf $dst_dir/librispeech-lexicon.txt $local_dir/librispeech-lexicon.txt
ln -sf $dst_dir/librispeech-vocab.txt $local_dir/librispeech-vocab.txt
echo "Done successfully"
exit 0