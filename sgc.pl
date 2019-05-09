#!/usr/bin/perl -w
use FindBin qw($Bin);
use Cwd qw(getcwd);
use lib "$Bin/lib";
use sgio;
use errors;

# Check arguments & setup input, outputpath
($input, $output, $fileexists) = sgio::checkarg();
print "Input path: " . $input . "\n";
print "Output path: " . $output . "\n";

# Load config files
($globalcfg, $commhead, $commfunc) = sgio::loadcfg("c");
print "HEADER\n$commhead\n";
print "FUNCTION COMMENT\n$commfunc\n";

# Open input & output files
open INPUT, "<$input";
open OUTPUT, ">$output";

# Write header comments
print OUTPUT $commhead;

# write include header
print OUTPUT "#include \"$ARGV[1]\"\n\n";


# Read all input file 
$inputstring = "";
$commentflag = 0;
while ($line = <INPUT>) {
    if ($commentflag) {
        if (($c = index($line, "*/")) != -1) {
            if (length($line) > $c + 2) {
                $line = substr $line, $c + 2;
            } else {
                $line = "";
            }
            $commentflag = 0;
        }
        else { next; };
    }
    if (($n = index($line, "//")) != -1) {
        $line = substr $line, 0, $n;
    }
    if (($c1 = index($line, "/*")) != -1) {
        if (($c2 = index($line, "*/")) > $c1) {
            $line = substr($line, 0, $c1) . substr($line, $c2 + 2);
        } else {
            $commentflag = 1;
            next;
        }
    }
    $line =~ s/^\s+|\s+$//g;
    if (substr($line, 0, 1) =~ /[^#]/ && length($line)) {
        $inputstring .= "$line\n";
    }
    
}
print $inputstring;

# Parse input strings
$inputstring =~ s/\n//g;
@lines = split '\;', $inputstring;
foreach my $line (@lines) {
    $w1 = substr $line, 0, ($n = index($line, " "));
    print "$w1\n";
    if ($w1 =~ /extern/) {
        # Global variables
        $line = substr $line, $n + 1;
        $line =~ s/^\s+//;
        print OUTPUT "$line\;\n\n";
    } elsif ($w1 =~ /struct/) {
    } elsif ($w1 =~ /typedef/) {
    } elsif (($n = index($line, "(")) != -1) {
        # Functions
        # Create Comment
        $funcstr = substr $line, 0, $n;
        $argstr = substr $line, $n + 1, rindex($line, ")") - $n - 1;
        @args = split /,/, $argstr;
        $argstr = "";
        if ($args[0]) {
            $args[0] =~ s/^\s+//;
            if ($args[0]) {
                $argstr .= "$args[0] - ";
                for (my $k = 1; $k < $#args; $k++) {
                    $args[$k] =~ s/^\s+//;
                    $argstr .= "\n*                   $args[$k] - ";
                }
            }
        }
        
        $comment = $commfunc;
        $comment =~ s/<FUNC>/$funcstr/g;
        $comment =~ s/<ARGV>/$argstr/g;
        print OUTPUT "$comment";
        print OUTPUT "$line\n{\n}\n\n";


    }

}
close INPUT;
close OUTPUT;

