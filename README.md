# style-check-html
The style-check-html tool is a patch for the [style-check.rb](http://www.cs.umd.edu/~nspring/software/style-check-readme.html).

The original [style-check.rb](http://www.cs.umd.edu/~nspring/software/style-check-readme.html) tool identifies common writing mistakes in LaTeX files and suggests possible corrections.
This patch only modifies the code that displays these suggestions to the user. Instead of obtaining the output in text-mode, users have now the "-w" option to receive the output in HTML format.

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
```

Open the resulting HTML file in your Web browser:
```
firefox test-dirty.html
```

The report contains a header with checkboxes and the number of suggestions being presented from the total.
Deselecting the checkbox for some category will remove the suggestions from this category from the view.
The entry for each suggestion contains the file where the suggestion was found, the original sentence, the reason it was issued, a possible solution, and the pattern triggering the suggestion.
Additionally, one may remove one entry at time by clicking on the "X" button at the right-side as it is corrected in the text.

The step-by-step tutorial on how to install the style-check.rb tool system-wide is still available in the original style-check's website (http://www.cs.umd.edu/~nspring/software/style-check-readme.html).


