#!/usr/bin/perl

BEGIN {
    use strict;
    use warnings;
    
    our $method;
    
    srand();
}

sub get_rand {
    return rand(shift @_);
}

sub read_roster {
    my $filename = shift @_;
    open(my $file, "<", $filename) || die "[FATAL] Could not read roster information file '".$filename."':".$!;

    my @roster;
    my $category, $n, $state = -1;
    while (my $a = <$file>) {
        if($state == -1) {
            $a =~ m/^\s*method\s*(.+)\s*\n/g;
            if (defined $1) { $method = $1; $state = 0; }
        } elsif($state == 0) {
            $a =~ m/^\[\s*(.+)\s*\]\s*\n/g;
            if (defined $1) { $category = $1; $state = 1; }
        } elsif($state == 1) {
            $a =~ m/^\s*([0-9])+\s*\n/g;
            if (defined $1) { $n = $1; $state = 2; }
        } elsif($state == 2) {
            $a =~ m/^\s*(.+)\s*\n/g;
            if (defined $1) {
                my @candidates = split(', ', $1);
                push(@roster, [$category, $n, \@candidates]);
                $state = 0; 
            } #foreach my $c (@candidates) { print "$c, "; } print "\n";
        }
    }
    
    close($file);
    
    return @roster;
}

sub roll {
    my $filename = shift @_;
    open(my $file, ">", $filename) || die "[FATAL] Could not create or open roll output file '".$filename."':".$!;
    
    my @roster = @_;
    
    foreach $c (@roster) {
        my $category = $c->[0];
        my $n        = $c->[1];
        my @candidates = @{$c->[2]};
        my @roll;
        
        printf $file "%s:\t", $category;
        foreach my $k (1..$n) {
            push (@roll, $candidates[get_rand($#candidates+1)]);
        }
        foreach my $r (@roll) { print $file "$r "; } print $file "\n";
    }
    
    close($file);
}


my @roster = read_roster("./roster.txt");
roll("./roll.txt", @roster);
