#!/usr/bin/perl -w
package sgio;
use FindBin qw($Bin);
use Cwd qw(getcwd);
use POSIX qw(strftime);
use lib $Bin;
use errors;

use Exporter qw(import);
our @EXPORT_OK = qw(checkarg getpaths loadcfg);

$inputpath = "";
$outputpath = "";
$triggerexist = 0;
%globalconfig;
$commheader = "";
$commfunction = "";

sub checkarg
{
    if ($#ARGV < 0) {
        # No Arguments
        # Same as -h or --help
        help();
        die;
    }
    elsif ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") {
        # some helps
        help();
        die;
    }
    elsif ($ARGV[0] eq "-o")
    {
        getpaths();
    }
    else
    {
        # Same as -h or --help
        help();
        die;
    }
    return ($inputpath, $outputpath, $triggerexist);
}
sub help {
    print "Usage: sgc -o \"input\" \"output\"\n"
}
sub getpaths {
    if ($#ARGV < 1) {
        errors::printerror(0);
        die;
    }
    $inputpath = getcwd . "/" . $ARGV[1];
    if (not -e $inputpath) {
        # Check argument 1
        errors::printerror(2, 1);
    }
    else {
        if ($#ARGV > 1) {
            $outputpath = getcwd . "/" . $ARGV[2];
        } else {
            $lastdot = rindex $inputpath, ".";
            $outputpath = substr $inputpath, 0, $lastdot;
            $outputpath = $outputpath.".c";
        }
        checkpath($outputpath);
    }

}
sub checkpath
{
    my $dir = substr $_[0], 0, rindex($_[0], "/"); 
    if (not -e $dir) {
        errors::printerror(2, 2);
        die;
    }
    if (-e $_[0]) {
        print "File already exists(" . $outputpath . "). Do you want to overwrite? (y/n): ";

        $key = substr <STDIN>, 0, 1;
        die if ($key eq "n");

        while (not ($key eq "y")) {
            print "Please answer by y or n: ";
            $key = substr <STDIN>, 0, 1;
            die if ($key eq "n");
        }
        $triggerexist = 1;
    }
}
sub loadcfg
{
    # Get current date
    my $date = strftime "%m/%d/%Y", localtime;
    print "Today: $date\n";

    $configpath = "$Bin/cfg/global.txt";
    open CFG, "<$configpath";
    while ($line = <CFG>) {
        $line =~ s/\n//g;
        @split = split "=", $line;
        $globalconfig{$split[0]} = $split[1];
    }
    close CFG;
    if ($_[0] eq "c") {
        
        $configpath = "$Bin/cfg/c.txt";
        open CFG, "<$configpath";
        while ($line = <CFG>) {
            if ($line eq "<HEADER>\n") {
                while(($line = <CFG>) ne "</HEADER>\n") {
                    $commheader = $commheader . $line;
                }
            } elsif ($line eq "<FUNCTION>\n") {
                while(($line = <CFG>) ne "</FUNCTION>\n") {
                    $commfunction = $commfunction . $line;
                }
            }
        }
        close CFG;
    }
    $lastslash = rindex $outputpath, "/"; 
    $filename = substr $outputpath, $lastslash + 1;
    $commheader =~ s/<FILE>/$filename/g;
    $commheader =~ s/<AUTH>/$globalconfig{'AUTH'}/g;
    $commheader =~ s/<DATE>/$date/g;

    return \%globalconfig, $commheader, $commfunction;
}

return 1;
