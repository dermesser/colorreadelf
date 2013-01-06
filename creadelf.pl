#!/usr/bin/perl
#

use warnings;
use strict;

use Term::ANSIColor;

# Subs

sub print_color($$)
{
    my $color = shift @_;
    my $text = shift @_;

    print(color($color));
    print($text);
    print(color('reset'));
}

# Colors

my $normal = color("reset");

my $address = color("green");
my $timestamp = color("on_cyan");
my $so = color("red");
my $sym = color("blue");
my $symtableentry = color("cyan");
my $section = color("magenta");

# Obtain readelf output

my $readelf = `which readelf`;
chomp($readelf);

my $flag;
my $file;

if ( $ARGV[0] =~ m/-[a-z]/ )
{
    $flag = $ARGV[0];
    $file = $ARGV[1];
} else
{
    $flag = '-a';
    $file = $ARGV[0];
}

my $readelf_output = qx{$readelf $flag $file};

my @lines = split("\n",$readelf_output);

my $in_sym_table = 0;

foreach my $line (@lines)
{

    # all hex strings
    $line =~ s/((?<![A-Za-z])(0x)?[0-9a-f]{5,})/${address}${1}${normal}/g;
    # all hex strings with 0x, even shorter than 5
    $line =~ s/(0x[0-9a-f]+)/${address}${1}${normal}/g;
    # timestamps
    $line =~ s/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/${timestamp}${1}${normal}/g;
    # shared objects
    $line =~ s/([\w\d\-\/]+\.so(\.\d+)?)/${so}${1}${normal}/g;
    # SYMBOLS
    $line =~ s/(?<![\w-])([A-Z_]{3,})(?![\w-])/${sym}${1}${normal}/g;
    # .sections
    $line =~ s/(?<![0-9a-zA-Z])(\.[a-zA-Z\._-]+)/${section}${1}${normal}/g;
    
    if ($in_sym_table == 1)
    {
        # if we already substitutde a .dynsym entry, don't try to substitute other function names in this line
        if ( 0 == $line =~ s/(?<![\w\d])([a-zA-Z0-9_]+@[A-Za-z0-9_\.]+)/${symtableentry}${1}${normal}/g )
        {
            $line =~ s/(?<![\w\d])([A-Z]?[a-z_]{3,})/${symtableentry}${1}${normal}/g
        }
    }
    
    if ( $line =~ m/(Sym\. Name|Ndx)/ )
    {
        $in_sym_table = 1;
    } elsif ( $line =~ m/^\s*$/ )
    {
        $in_sym_table = 0;
    }

    print $line . "\n";
}

