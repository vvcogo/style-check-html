# style-check-html
A patch that allows users to print reports from style-check.rb in HTML format.
This repository contains only the patch since the original software is available in another website (http://www.cs.umd.edu/~nspring/software/style-check-readme.html).
The option "-w" to write the output in HTML format is the only difference in the command line.

Downloading the code and patching it:
```
wget http://www.cs.umd.edu/~nspring/software/style-check-current.tar.gz
wget https://raw.githubusercontent.com/vvcogo/style-check-html/master/style-check-0.14.patch
tar -zxvf style-check-current.tar.gz
cd style-check-0.14/
patch style-check.rb < ../style-check-0.14.patch
```

Testing the new code:
```
ruby style-check.rb -w test-dirty.tex > test-dirty.html
firefox test-dirty.html
```

User- or system-wide installation is still available in the original style-check's website (http://www.cs.umd.edu/~nspring/software/style-check-readme.html).


