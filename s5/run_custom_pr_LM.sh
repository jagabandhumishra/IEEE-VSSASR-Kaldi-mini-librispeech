#!/usr/bin/env bash

# Change this location to somewhere where you want to put the data.
# written by Jagabandhu Mishra 15/07/2021, IEEE Summer school ASR



data=./corpus



. ./cmd.sh
. ./path.sh

stage=-1
. utils/parse_options.sh

set -euo pipefail

if [ $stage -le -1 ]; then
rm -rf data
rm -rf mfcc
rm -rf exp
fi


ncores=`cat /proc/cpuinfo | grep processor | wc -l`    ## provide information about number of cores
#############################  Dataset download from openslr ##################### 
if [ $stage -le 0 ]; then
  mkdir -p $data

  for part in dev-clean-2 train-clean-5; do
    local/data_untar.sh $data $part
  done
fi
############################   Language model download from openslr ##############

if [ $stage -le 1 ]; then
  local/data_pre_lm.sh $data data/local/lm
fi

<<com
######################### flac installation  ################################
# check in your system by putting flac command prompt, if it is not there then only install it

# open another command prompt (ctrl+alt+t) 
# wget  https://downloads.xiph.org/releases/flac/flac-1.3.2.tar.xz 
# xz -d flac-1.3.2.tar.xz
# tar -xvf flac-1.3.2.tar
# cd flac-1.3.2
# ./configure
# make
# sudo make install
# flac (to check it is installed or not, it will show the following)


===============================================================================
flac - Command-line FLAC encoder/decoder version 1.3.2
Copyright (C) 2000-2009  Josh Coalson
Copyright (C) 2011-2016  Xiph.Org Foundation

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
===============================================================================

This is the short help; for all options use 'flac --help'; for even more
instructions use 'flac --explain'

Be sure to read the list of known bugs at:
http://xiph.org/flac/documentation_bugs.html

To encode:
  flac [-#] [INPUTFILE [...]]

  -# is -0 (fastest compression) to -8 (highest compression); -5 is the default

To decode:
  flac -d [INPUTFILE [...]]

To test:
  flac -t [INPUTFILE [...]]

com

############################### Data preparation----> Kaldi specific format ######

if [ $stage -le 2 ]; then
  # format the data as Kaldi data directories
  for part in dev-clean-2 train-clean-5; do
    # use underscore-separated names in data directories.
    local/data_prep.sh $data/LibriSpeech/$part data/$(echo $part | sed s/-/_/g)
  done
fi



###########################  MFCC feature extraction   ###################################
echo '######################### feature extraction started ######################################'
date
if [ $stage -le 3 ]; then
  mfccdir=mfcc
  # spread the mfccs over various machines, as this data-set is quite large.
  if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
    mfcc=$(basename mfccdir) # in case was absolute pathname (unlikely), get basename.
    utils/create_split_dir.pl /export/b{07,14,16,17}/$USER/kaldi-data/egs/librispeech/s5/$mfcc/storage \
      $mfccdir/storage
  fi

  for part in dev_clean_2 train_clean_5; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj "$ncores" data/$part exp/make_mfcc/$part $mfccdir
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done

fi
echo '######################### feature extraction completed successfully ######################################'
date
######################################################################
# to check mfcc feature vector
#copy-feats ark:mfcc/raw_mfcc_dev_clean_2.1.ark ark,t:mfcc/raw_mfcc_dev_clean_2.1.txt



############################### Data preparation for language model #################
# dictionary preparation
echo '######################### dictionary preparation started ######################################'
date
if [ $stage -le 4 ]; then
 local/prepare_dict.sh --stage 3 --nj "$ncores" --cmd "$train_cmd" \
    data/local/lm data/local/lm data/local/dict_nosp

fi


# language preparation



if [ $stage -le 5 ]; then



 utils/prepare_lang.sh data/local/dict_nosp \
    "<UNK>" data/local/lang_tmp_nosp data/lang_nosp

fi


if [ $stage -le 6 ]; then

local/format_lms.sh --src-dir data/lang_nosp data/local/lm

fi


#


echo '######################### dictionary preparation completed successfully ######################################'
date

#################################
# To see the language model  (meaning to be asked???)
# fstprint -isymbols=data/lang_nosp/words.txt -osymbols=data/lang_nosp/words.txt data/lang_nosp/G.fst
#################################################################################################
# Get the shortest 500 utterances first because those are more likely
# to have accurate alignments.

if [ $stage -le 7 ]; then
  utils/subset_data_dir.sh --shortest data/train_clean_5 500 data/train_500short
fi
############  Train monophone model  ####################

if [ $stage -le 8 ]; then
  # TODO(galv): Is this too many jobs for a smaller dataset?
  steps/train_mono.sh --boost-silence 1.25 --nj "$ncores" --cmd "$train_cmd" \
    data/train_500short data/lang_nosp exp/mono

  
fi
#########################################
#http://kaldi-asr.org/doc/glossary.html
#to check the model statistics
# gmm-info exp/mono/final.mdl
## To see the phone transition   (meaning of this ???)
# show-transitions data/lang_nosp/phones.txt exp/mono/final.mdl |less
#gmm-copy --binary=false exp_FG/tri_8_2000/final.mdl exp_FG/tri_8_2000/final.txt
########################################################
# phone allignment

if [ $stage -le 9 ]; then
steps/align_si.sh --boost-silence 1.25 --nj "$ncores" --cmd "$train_cmd" \
    data/train_clean_5 data/lang_nosp exp/mono exp/mono_ali_train_clean_5

fi

## making graph
if [ $stage -le 10 ]; then
utils/mkgraph.sh  --mono data/lang_nosp_test_tgsmall exp/mono exp/mono/graph

fi

echo '######################### mono phone decoding  started ######################################'
date
## Decoding
if [ $stage -le 11 ]; then
steps/decode.sh --nj "$ncores" --cmd "$decode_cmd" exp/mono/graph data/dev_clean_2 exp/mono/decode
fi
## see the wer|head
cat exp/mono/decode/wer*|grep WER|sort|head -1
echo '######################### mono phone decoding  done successfully ######################################'
date
 ##################  tri phone training
 # train delta.sh is generaly used for tri-phone training


if [ $stage -le 12 ]; then
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train_clean_5 data/lang_nosp exp/mono_ali_train_clean_5 exp/tri1

  steps/align_si.sh --nj "$ncores" --cmd "$train_cmd" \
    data/train_clean_5 data/lang_nosp exp/tri1 exp/tri1_ali_train_clean_5
fi

echo '######################### tri phone phone decoding  started ######################################'
date

if [ $stage -le 13 ]; then

utils/mkgraph.sh  data/lang_nosp_test_tgsmall exp/tri1 exp/tri1/graph

steps/decode.sh --nj "$ncores" --cmd "$decode_cmd" exp/tri1/graph data/dev_clean_2 exp/tri1/decode

fi
## see the wer|head
cat exp/tri1/decode/wer*|grep WER|sort|head -1

echo '######################### tri phone phone decoding  done successfully ######################################'
date


# train an LDA+MLLT system.
if [ $stage -le 14 ]; then
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    data/train_clean_5 data/lang_nosp exp/tri1_ali_train_clean_5 exp/tri2b

  # Align utts using the tri2b model
  steps/align_si.sh  --nj "$ncores" --cmd "$train_cmd" --use-graphs true \
    data/train_clean_5 data/lang_nosp exp/tri2b exp/tri2b_ali_train_clean_5
fi

# Train tri3b, which is LDA+MLLT+SAT
if [ $stage -le 17 ]; then
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    data/train_clean_5 data/lang_nosp exp/tri2b_ali_train_clean_5 exp/tri3b
fi
echo '######################### tri phone phone with MLLT+SAD decoding started  ######################################'
date

if [ $stage -le 15 ]; then

utils/mkgraph.sh  data/lang_nosp_test_tgsmall exp/tri3b exp/tri3b/graph

steps/decode_fmllr.sh --nj "$ncores" --cmd "$decode_cmd" exp/tri3b/graph data/dev_clean_2 exp/tri3b/decode

fi
## see the wer|head
cat exp/tri3b/decode/wer*|grep WER|sort|head -1

echo '######################### tri phone phone with MLLT+SAD decoding done successfully  ######################################'
date
