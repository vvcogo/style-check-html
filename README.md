# style-check-html
The style-check-html tool is a patch for the [style-check.rb](http://www.cs.umd.edu/~nspring/software/style-check-readme.html).

The original [style-check.rb](http://www.cs.umd.edu/~nspring/software/style-check-readme.html) tool identifies common writing mistakes in LaTeX files and suggests possible corrections.
This patch only modifies the code that displays these suggestions to the user. Instead of obtaining the output in text-mode, users have now the "-w" option to receive the output in HTML format.

The installation process is exactly the same as the original tool. Execute the following commands to obtain it: 
```
wget https://github.com/vvcogo/style-check-html/releases/download/v0.14/style-check-html-0.14.tar.gz
tar -zxvf style-check-html-0.14.tar.gz
cd style-check-0.14/
```
And the following to install it system-wide:
```
sudo make install
```
or user-wide:
```
make user-install
```

You are ready to use the patched version of the style-check.rb tool and to obtain the output in HTML format:
```
style-check.rb -w my-article.tex > my-article.html
```

Opening the resulting file in your Web browser is the last step:
```
firefox my-artile.html
```

The report contains a header with checkboxes and the number of suggestions being presented from the total.
Deselecting the checkbox for some category will remove the suggestions from this category from the view.
The entry for each suggestion contains the file where the suggestion was found, the original sentence, the reason it was issued, a possible solution, and the pattern triggering the suggestion.
Additionally, one may remove one entry at time by clicking on the "X" button at the right-side as it is corrected in the text.
