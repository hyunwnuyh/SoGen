#!/usr/bin/perl -w
package sgio;
use FindBin qw($Bin);
use Cwd qw(getcwd);
use POSIX qw(strftime);
use File::Path qw(make_path);
use File::Find qw(finddepth);
use lib $Bin;
use errors;

use Exporter qw(import);
our @EXPORT_OK = qw(checkarg loadcfg);

$op_help = 0;
$op_recursive = 0;
$op_force = 0;

$inputdir = "";
$outputdir = "";
$inputpath = "";
$outputpath = "";

our @inputfiles = ();
our @outputfiles = ();

sub checkarg {
    $argn = 0;
    if ($#ARGV < 0) {
        # No Arguments
        # Same as -h
        help();
        die;
    }
    if (substr($ARGV[0], 0, 1) eq "-") {
        $argn++;
        for (my $i = 1; $i < length($ARGV[0]); $i++) {
            $c = substr $ARGV[0], $i, 1;
            if ($c eq "h") {
                $op_help = 1;
            } elsif ($c eq "r") {
                $op_recursive = 1;
            } elsif ($c eq "f") {
                $op_force = 1;
            }
        }
    } 

    if ($op_help) {
        help();
        die;
    }
    if ($op_recursive) {
        # sgc -r (dir) (dir)
        $inputdir = getcwd;
        $outputdir = $inputdir;
        $inputargv = "";
        if ($#ARGV > 0) {
            if (-d "$inputdir/$ARGV[1]") {
                $inputdir .= "/$ARGV[1]";
            } else {
                $inputargv = "/$ARGV[1]";
            }
            if ($#ARGV > 1) {
                $outputdir = getcwd . "/$ARGV[2]";
            } else {
                $outputdir = $inputdir;
            }
        } else {
            $inputdir = getcwd;
            $outputdir = $inputdir;
        }
        print "--------------Files--------------\n";
        File::Find::find(sub {
                $inputpath = $File::Find::name;
                my $i = rindex($inputpath, ".");
                if (-f $inputpath && substr($inputpath, $i + 1) eq "h") {
                    print "Input: $inputpath\n";
                    $outputpath = substr($inputpath, 0, $i) . ".c";
                    $outputpath =~ s/$inputdir//g;
                    $outputpath = "$outputdir$outputpath";
                    if (checkoutput()) {
                        push @inputfiles, $inputpath;
                        push @outputfiles, $outputpath;
                        print "Output: $outputpath\n";
                    }
                }
            }, $inputdir . $inputargv);
    } else {
        # sgc file (file)
        if ($#ARGV >= $argn) {
            $inputpath = getcwd . "/$ARGV[$argn]";
            if (not checkinput()) {
                die;
            }
            if ($#ARGV >= $argn + 1) {
                $outputpath = getcwd . "/$ARGV[$argn + 1]";
            } else {
                $lastdot = rindex $inputpath, ".";
                $outputpath = substr $inputpath, 0, $lastdot;
                $outputpath .= $_[0];
            }
            if (not checkoutput()) {
                die;
            }
            push(@inputfiles, $inputpath);
            push(@outputfiles, $outputpath);
        } else {
            errors::printerror(1);
            die;
        }
    }
    return (\@inputfiles, \@outputfiles, $#inputfiles + 1);
}

sub checkinput {
    print "$inputpath\n";
    if (not -f $inputpath) {
        errors::printerror(2);
        return 0;
    }
    return 1;
}

sub checkoutput {
    my $dir = substr $outputpath, 0, rindex($outputpath, "/"); 
    if (not -e $dir) {
        make_path($dir);
    } elsif (not -d $dir) {
        errors::printerror(3);
        return 0;
    }
    if ($op_force) {
        return 1;
    }
    if (-e $outputpath) {
        print "File already exists(" . $outputpath . "). Do you want to overwrite? (y/n): ";

        $key = substr <STDIN>, 0, 1;
        return 0 if ($key eq "n");

        while (not ($key eq "y")) {
            print "Please answer by y or n: ";
            $key = substr <STDIN>, 0, 1;
            return 0 if ($key eq "n");
        }
    }
    return 1;
}
sub help {
    print "\n";
    print "Usage 1: sgc [-options] input [output]\n";
    print "Usage 2: sgc -r[options] [input] [output]\n";
    print "\n";
    print "Possible options\n";
    print "-------------------------------------\n";
    print "r            recursive\n";
    print "f            force (always overwrite)\n";
    print "h            help (ignore other opts)\n";
    print "\n";
}
sub loadcfg {
    $commheader = "";
    $commfunction = "";
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

    $configpath = "$Bin/cfg/$_[0]";
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
    $lastslash = rindex $outputpath, "/"; 
    $filename = substr $outputpath, $lastslash + 1;
    $commheader =~ s/<FILE>/$filename/g;
    $commheader =~ s/<AUTH>/$globalconfig{'AUTH'}/g;
    $commheader =~ s/<DATE>/$date/g;

    return $commheader, $commfunction;
}
return 1;
