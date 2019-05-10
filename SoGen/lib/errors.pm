#!/usr/bin/perl -w
package errors;
use Exporter qw(import);

our @EXPORT_OK = qw(printerror);

#errors string array
our @errors = (
    "Error 0: not enough arguments",
    "Error 1: invalid arguments",
    "Error 2: No such file or directory",
    "Error 3: File/Directory already exists"
);

sub printerror
{
    
    print $errors[$_[0]];
    if ($#_ > 0)
    {
        print $_[1];
    }
    print "\n";
}
return 1;
