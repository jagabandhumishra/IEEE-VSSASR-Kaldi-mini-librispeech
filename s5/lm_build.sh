#!/usr/bin/env bash

kaldi_root_dir=$1

n_gram=$2 # This specifies bigram or trigram. for bigram set n_gram=2 for tri_gram set n_gram=3

rm -rf data/local/lang_tmp_nosp/lm_phone_bg.ilm.gz
rm -rf data/local/lang_tmp_nosp/oov.txt
$kaldi_root_dir/tools/irstlm/bin/build-lm.sh -i data/train_clean_5/lm_train.txt -n $n_gram -o data/local/lang_tmp_nosp/lm_phone_bg.ilm.gz
gunzip -c data/local/lang_tmp_nosp/lm_phone_bg.ilm.gz | utils/find_arpa_oovs.pl data/lang_nosp/words.txt  > data/local/lang_tmp_nosp/oov.txt


rm -rf data/lang_nosp/G.fst
gunzip -c data/local/lang_tmp_nosp/lm_phone_bg.ilm.gz | grep -v '<s> <s>' | grep -v '<s> </s>' | grep -v '</s> </s>' | grep -v 'SIL' | $kaldi_root_dir/src/lmbin/arpa2fst - | fstprint | utils/remove_oovs.pl data/local/lang_tmp_nosp/oov.txt | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=data/lang_nosp/words.txt --osymbols=data/lang_nosp/words.txt --keep_isymbols=false --keep_osymbols=false | fstrmepsilon > data/lang_nosp/G.fst
$kaldi_root_dir/src/fstbin/fstisstochastic data/lang_nosp/G.fst