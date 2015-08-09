#!/usr/bin/env ruby

# copyright 2004 Neil Spring
# distributed under the terms of the GNU General Public License.

# a simple script to check against a ruleset of "forbidden"
# phrases and spellings.  it is intended as a quick check
# against verbose phrases, overused expressions, incorrect
# spellings, and inconsistent capitalization or hypenation.

# complexity in this script arised from handling basic tex
# comments and ignoring fragments of tex that are allowed to 
# violate style (such as the bibtex tag inside \cite{})

# the dictionary of censored phrases is a compound of
# ~/.style-censor, ./censor-dict (for historical reasons),
# and /etc/style-censor, as well as all files in
# ~/.style-check.d, for particularly egregious violations
# (such as spelling errors and common double-word problems).

# this script is not intended to substitute for a spell
# checker, a grammar checker, or a proof-reader.  And the 
# phrases listed aren't necessarily forbidden; they may 
# simply be discouraged.  Those that are particularly weak
# should be annotated with a question mark at the end of the
# explanation.  (the behavior of the script does not currently
# depend on this syntax.  someday it may.)

# Bugs 

# - misspelled words may not be recognized if capitalized.
# This is a consequence of the script's goal of watching for
# uniform upper- and lower- case project names and such.  

# - expressions with % in them won't be matched; the %
# character is reserved for explanatory text.

# if run with -g, insert a space between line and column,
# so that gedit linkparser.py at least parses the file and 
# line number

require 'digest'

Gedit_Mode = if(ARGV.include?("-g"))
               ARGV.delete("-g")
               true
             else
               false
             end

$VERBOSE=false
$WEB=false
if(ARGV[0] == "-v") then
  ARGV.shift
  $VERBOSE = true
elsif(ARGV[0] == "-w")then
  ARGV.shift
  $WEB = true
end

override_rule_paths = nil
if(ARGV[0] == "-r") then
  ARGV.shift
  param = File.expand_path(ARGV.shift)
  if(test(?d, param)) then
    override_rule_paths = Dir.glob(param + "/*")
  elsif(test(?f, param)) then
    override_rule_paths = param
  else
    raise "what is that rule path you tried to specify?"
  end
end

$exit_status = 0

ignoredCommands = "ref|href|url|input|bibliography|cite|nocite|cline|newcommand|includegraphics|begin|end|label".split('|')
PctCensored_phrases = Hash.new  # before stripping comments
PreCensored_phrases = Hash.new  # before stripping cites
Censored_phrases = Hash.new     # the rest.
PathList = if(override_rule_paths) then 
             override_rule_paths
           else
             Dir.glob("/etc/style-check.d/*") + 
                 Dir.glob(ENV["HOME"] + "/.style-check.d/*") + 
                     [ ENV["HOME"] + "/.style-censor", "./censor-dict", "/etc/style-censor", "./style-censor" ]
           end

# $prefilter = nil

PathList.map { |rulefilename| 
  if ( Kernel.test(?f, rulefilename) && rulefilename !~ /~$/ ) then
    # $stderr.print "loading #{rulefilename}"
    File.open(rulefilename).each_with_index { |phr,lnnum_minus_one|
      #if ( ! phr.scan(~ /^# / ) then 
      expression, reason = phr.split(/\s*%\s*/) 
      if( reason ) then 
        begin
          Censored_phrases[ 
            case reason.split(/\s+/)[0]
            when 'syntax'
              Regexp.new(expression.chomp) 
            when 'capitalize'
              Regexp.new('\b' + expression.chomp + '\b' ) 
            when 'phrase' 
              # $stderr.puts('\b' + expression.chomp.gsub(/ +/, '\s+').gsub(/([a-zA-Z])$/, '\1\b')) 
              Regexp.new('\b' + expression.chomp.gsub(/ +/, '\s+').gsub(/([a-zA-Z\)])$/, '\1\b'), Regexp::IGNORECASE ) 
            when 'spelling' 
              Regexp.new('\b' + expression.chomp + '\b', Regexp::IGNORECASE ) 
            when 'ignoredcommand'
              ignoredCommands.push(expression.chomp)
              nil
            else
              puts "warning: no class specified for %s at %s:%d" % [ expression, rulefilename, lnnum_minus_one + 1 ]
              Regexp.new('\b' + expression.chomp + '\b' ) 
            end
          ] = ( reason or "" ) + "  (matched '" + expression.chomp + 
            "' in %s:%d)" % [ rulefilename, lnnum_minus_one + 1 ]
          # end
        rescue RegexpError => e
          $stderr.puts "#{rulefilename}:#{lnnum_minus_one + 1}: Error: #{e}"
          exit 1
        end
        Censored_phrases.delete(nil)
      end
    }
    else 
    []
  end
}

# $prefilter = Regexp.new( "(" + Censored_phrases.keys.map { |r| r.source}.join("|") + ")" )

# thanks to Adin Rivera for reporting a little bug in the next line.
PreCensored_phrases[ 
  Regexp.new(/\.~?\\cite/) ] = "syntax ~\\cite{} should precede the period."
PreCensored_phrases[ 
  Regexp.new(/\b(from|in|and|with|see)[~ ]+\\cite/) ] = "syntax don't cite in the sentence as 'in [x]', cites are not nouns.  Prefer: Smith et al.~\\cite{...} show ... ."
PreCensored_phrases[ 
  Regexp.new(/[^\.\n]\n\n/) ] = "syntax paragraphs should end with a sentence end"
PreCensored_phrases[ 
  Regexp.new(/(Table|Figure|Section)[ \n]\\ref/) ] = "syntax Table, Figure, and Section refs should have a non-breaking space"
PreCensored_phrases[ 
  Regexp.new(/(table|figure|section)~\\ref/) ] = "syntax Table, Figure, and Section refs should be capitalized"
PreCensored_phrases[ 
  Regexp.new(/\\url\{(?!http|ftp|rtsp|mailto)/) ] = "syntax ~\\url{} should start with http:// (or ftp or rtsp or maybe mailto)."

PctCensored_phrases[ 
  Regexp.new(/[0-9]%/) ] = "syntax a percent following a number is rarely an intended comment."
# PctCensored_phrases[ 
#   Regexp.new(/[<>]/) ] = "a less than or greater than outside math mode shows other characters."

if(Censored_phrases.length == 0) then
  puts "no style-censor phrases found.  write some in ./style-censor."
  exit 1
end
De_comment = Regexp.new('(([^\\\\]%.*)|(^%.*))$')
# though newcommand could gobble both parameters...
De_command = Regexp.new('(~?\\\\(' + ignoredCommands.join('|') + ')(\[[^\]]*\])?\{[^{}]*\})')
De_verb = Regexp.new('\\\\verb(.)[^\1]*\1')
De_math = Regexp.new('[^\\\\]\$.*[^\\\\]\$|^\$.*[^\\\\]\$')

def do_cns(line, file, linenum, phra_hash)
  # if line =~ /\\caption/ && file =~ /Mapping/ then
    # puts "validating: '#{line}'"
  # end
  m = nil
  r = nil # so we can keep it as a side-effect of the detect call
  detected = nil
  windows_detect_bug_avoider = nil
  # if m = $prefilter.match(line) then
    if(detected = phra_hash.keys.detect { |r| m = r.match(line) and (line.index("\n") == nil or m.begin(0) < line.index("\n"))  } ) then
      matchedlines = ( m.end(0) <= ( line.index("\n") or 0 ) ) ? line.gsub(/\n.*/,'') : line.chomp
      if($WEB) then
        puts "<table id=\""+Digest::SHA1.hexdigest(line.to_s+file.to_s+linenum.to_s)+"\" class=\""+phra_hash[detected].split(/\s+/)[0]+"\">"
        j=m.begin(0)+1;
		puts "<tr><th>File</th><td>"+file.to_s+" (line: "+linenum.to_s+", column: "+j.to_s+")<div class=\"x\"><button onclick=\"myFunction('"+Digest::SHA1.hexdigest(line.to_s+file.to_s+linenum.to_s)+"');\">X</button></div></td></tr>"
		puts "<tr><th>Original</th><td>%s</td></tr>" % [ matchedlines ]
		puts "<tr><th>Problem</th><td>%s</td></tr>" % [ m.to_s.tr("\n", ' ') ]
		if (phra_hash[detected]) then
      	  solution=phra_hash[detected].split("(matched")
		  puts "<tr><th>Solution</th><td>%s</td></tr>" % [ solution[0] ]
		  if (solution[1] != nil ) then
      	    puts "<tr><th>Trigger</th><td>%s</td></tr>" % [ solution[1][0..-2] ]
      	  end
		end
        puts "</table>"
      else		
        puts "%s:%d:%s%d: %s (%s)" % [ file, linenum, Gedit_Mode ? ' ': '', m.begin(0)+1, matchedlines, m.to_s.tr("\n", ' ') ]
      end
      $exit_status = 1 if(!phra_hash[detected] =~ /\?\s*$/) 
      if($VERBOSE && phra_hash[detected]) then
        puts "Solution: " + phra_hash[detected]
        phra_hash[detected] = nil # don't print the reason more than once
      end
    end
  # end
end
 
Input_files = ARGV
Input_files.delete_if { |f|
  if !test(?e, f) then
    $stderr.puts "WARNING: Input file #{f} does not exist.  skipping."
    true
  else
    false
  end  
}
if($WEB) then
	puts "<html>\n<head>\n<title>style_checker.rb</title>\n</head>\n<style>\nform{width:100%; text-align:center;font-size:10pt;}\ninput{vertical-align:bottom;margin-left:30px;}\ntable { width:95%; border-collapse: collapse; font-size:10pt; margin:10px 2.5%}\n.spelling th, #mySpelling{background-color:#FFC1C1;}\n.capitalize th, #myCapitalize{background-color:#FFF7C1;}\n.syntax th, #mySyntax{background-color:#C1E0FF;}\n.phrase th, #myPhrase{background-color:#C1FFD1;}\n#myUndefined{margin-left:30px;background-color: #eee;}\ntable, th, td { border: 1px solid black; padding: 5px;}\ntr{ width:100%}\ndiv{display:inline;}th{ text-align:left; width: 10%; background-color: #eee;}\ntd{ width:90%;}\n#myTotal{width:100%;margin-left:15px;font-size:10pt;}\ntable button{float:right; font-size:8pt; border: 1px solid black;width:15px;padding:0 1px 0 1px;text-align:center;}\np{ font-size: 10pt; text-align: center;}\n</style>\n<body><form id=\"aform\"><input type=\"checkbox\" id=\"inSpelling\" name=\"type\" value=\"spelling\" checked=\"checked\"><div id=\"mySpelling\">Spelling</div><input type=\"checkbox\" id=\"inCapitalize\" name=\"type\" value=\"capitalize\" checked=\"checked\"><div id=\"myCapitalize\">Capitalize</div><input type=\"checkbox\" id=\"inSyntax\" name=\"type\" value=\"syntax\" checked=\"checked\"><div id=\"mySyntax\">Syntax</div><input type=\"checkbox\" id=\"inPhrase\" name=\"type\" value=\"phrase\" checked=\"checked\"><div id=\"myPhrase\">Phrase</div><div id=\"myUndefined\">Undefined</div><br /><br /><div id=\"myTotal\"></div></form>"
end
Input_files.each { |f|
if($WEB) then
  puts "<h1>%s</h1>" % [ f ]
  end
  in_multiline_comment = 0
  in_multiline_verbatim = false
  in_multiline_equation = false
  # load the file, contents, but drop comments and other
  # hidden tex command pieces
  lines = File.open(f).readlines
  lines.each_with_index { |ln,i|
    do_cns( ln, f, i+1, PctCensored_phrases )
    ln.sub!(De_comment, '')
    # no, I don't know that comment environments nest and verbatim environments dont. 
    # I have no such cluefulness.
    if( ln =~ /\\begin\{comment\}/ ) then
      in_multiline_comment+=1
    elsif( ln =~ /\\end\{comment\}/ ) then
      in_multiline_comment-=1
    end
    if( ln =~ /\\begin\{verbatim\}/ ) then
      in_multiline_verbatim=true
    elsif( ln =~ /\\end\{verbatim\}/ ) then
      in_multiline_verbatim=false
    end
    if( ln =~ /\\begin\{(equation|math|eqnarray)\*?\}/ ) then
      in_multiline_equation=true
    elsif( ln =~ /\\end\{(equation|math|eqnarray)\*?\}/ ) then
      in_multiline_equation=false
    end
    if(in_multiline_comment == 0 && ! in_multiline_verbatim && ! in_multiline_equation)  then
      do_cns( ln, f, i+1, PreCensored_phrases )
      ln.gsub!(De_command, '~')
      ln.gsub!(De_verb, '~')
      ln.gsub!(De_math, '~')
      do_cns( (ln + ( lines[i+1] or "" ) + ( lines[i+2] or "" )).sub(De_comment, '').sub(De_command, '~'), f, i+1, Censored_phrases )
      
      # now try to make sure that paragraphs end with sentence
      # ending punctuation, such as a period, exclamation mark,
      # question mark, or perhaps a command-ending brace.
      if(lines.length > i+3) then
        checkstring = lines[i..(i+1)].map { |ln| 
          ln.sub!(De_comment, '');   
          ln.sub!(/\\[a-z]+=[0-9]+/, '');  # tex variable assignment; I format each on its own line.
          ln }.join 
        #if(checkstring =~ /SIGCOMM/) then
          #puts "%s:%d: argh: %s" % [ f, i, checkstring.gsub(/\n/, '\n') ];
        #end
        if(checkstring =~ /[a-z0-9][^\.\:\!\?\n}]\n\n/) then
        	if($WEB) then
          puts "<table id=\""+Digest::SHA1.hexdigest(f.to_s+i.to_s+checkstring.gsub(/\n/, '\n').to_s)+"\" class=\"syntax\">"
          j=(i+1);
      		puts "<tr><th>File</th><td>"+f.to_s+" (line: "+j.to_s+")<div class=\"x\"><button onclick=\"myFunction('"+Digest::SHA1.hexdigest(f.to_s+i.to_s+checkstring.gsub(/\n/, '\n').to_s)+"');\">X</button></div></td></tr>"
      		puts "<tr><th>Original</th><td>%s</td></tr>" % [ checkstring.gsub(/\n/, '\n') ]
      		puts "<tr><th>Problem</th><td>apparent bad paragraph break</td></tr>"
		      puts "</table>"
      		else
          puts "\n################################################################################\n%s:l%d: apparent bad paragraph break: %s" % [ 
            f, i+1, checkstring.gsub(/\n/, '\n') ];
            end
        end
      end
    end
  }
}
if($WEB) then
puts "
<script type=\"text/javascript\" src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js\"></script>
<script type=\"text/javascript\">
$('#aform').on
(
	'change', 'input[type=checkbox]', function(e) 
	{ 
		if (this.checked)
		{  
			switch(this.value){
				case 'phrase': $(\".phrase\").show(); break;
				case 'syntax':  $(\".syntax\").show(); break;
				case 'capitalize':  $(\".capitalize\").show(); break;
				case 'spelling':  $(\".spelling\").show(); break;
				case 'undefined': $(\".undefined\").show(); break;
			}
		} else {
			switch(this.value){
				case 'phrase': $(\".phrase\").hide(); break;
				case 'syntax':  $(\".syntax\").hide(); break;
				case 'capitalize':  $(\".capitalize\").hide(); break;
				case 'spelling':  $(\".spelling\").hide(); break;
				case 'undefined': $(\".undefined\").hide(); break;
			}
		}
			updateCounters();
	}	
);
$( window ).load(function() 
{
		updateCounters();
});
function myFunction(theHash){
	theHash = \"#\"+theHash;
	$(theHash).remove();
		updateCounters();
}

function updateCounters(){
	$(\"#myPhrase\").html( \"Phrase \(\" + $(\".phrase\").length+\")\"); 
	$(\"#mySyntax\").html( \"Syntax \(\" + $(\".syntax\").length+\")\"); 
	$(\"#myCapitalize\").html( \"Capitalize \(\" + $(\".capitalize\").length+\")\"); 
	$(\"#mySpelling\").html( \"Spelling \(\" + $(\".spelling\").length+\")\");	
	$(\"#myTotal\").html( \"Presenting \" + countVisible() +\" suggestions out of \"+$('table').length + \" identified \");	
}

function countVisible() {
	aCount=0;
	if($('#inSpelling').is(':checked')){
		aCount=aCount+$('.spelling').length;
	}
	if($('#inPhrase').is(':checked')){
		aCount=aCount+$('.phrase').length;
	}
	if($('#inSyntax').is(':checked')){
		aCount=aCount+$('.syntax').length;
	}
	if($('#inCapitalize').is(':checked')){
		aCount=aCount+$('.capitalize').length;
	}
	return aCount;
}

</script>
<p> This HTML was generated by a modified version of <a href=\"http://www.cs.umd.edu/~nspring/software/style-check-readme.html\" target=\"_blank\">style-check.rb</a> software.</p>\n</body>\n</html>"
	end
