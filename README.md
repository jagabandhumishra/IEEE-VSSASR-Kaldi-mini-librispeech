# IEEE-VSSASR-Kaldi-mini-librispeech

Please open terminal (using ctrl+alt+t) type: 

##### cd <Kaldi_root_path>/egs/                                          

#example : cd /home/jagabandhu/kaldi/egs/

##### git clone https://github.com/jagabandhumishra/IEEE-VSSASR-Kaldi-mini-librispeech

It will download a folder called IEEE-VSSASR-Kaldi-mini-librispeech to the kaldi/egs folder

In the same terminal type:


##### cd IEEE-VSSASR-Kaldi-mini-librispeech/s5


##### mkdir corpus   

This will create one corpus folder inside IEEE-VSSASR-Kaldi-mini-librispeech/s5 folder

Copy the downloaded content (all 5 files mentioned below) to the corpus folder


www.openslr.org/resources/11/3-gram.pruned.3e-7.arpa.gz

http://www.openslr.org/resources/11/librispeech-lexicon.txt

http://www.openslr.org/resources/11/librispeech-vocab.txt

www.openslr.org/resources/31/train-clean-5.tar.gz

www.openslr.org/resources/31/dev-clean-2.tar.gz

## Directory Structure

### corpus
 
 3-gram.pruned.3e-7.arpa.gz
 
 librispeech-lexicon.txt
 
 librispeech-vocab.txt
 
 train-clean-5.tar.gz
 
 dev-clean-2.tar.gz
 
## Run (please open the cmd.sh file and change the memory variable as per your local system specification and save it)

Open run_custom.sh file in text editor and set stage=0, after that save it and run below command in your current terminal.

##### ./run_custom.sh

Open run_custom_pr_LM.sh file in text editor set stage=0, after that save it and run below command in your current terminal.

##### ./run_custom_pr_LM.sh
