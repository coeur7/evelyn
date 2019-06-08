#!/usr/bin/perl

BEGIN {
    use strict;
    use warnings;
    use POSIX;
    
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
            }
        }
    }
    
    close($file);
    
    return @roster;
}

sub roll {
    my $filename = shift @_;
    open(my $file, ">", $filename) || die "[FATAL] Could not create or open roll output file '".$filename."':".$!;
    
    my @roster = @_;
    
    print "[EVELYN] Rolling according to the '".$method."' method.\n";
    foreach $c (@roster) {
        my $category = $c->[0];
        my $n        = $c->[1];
        my @candidates = @{$c->[2]};
        my @roll;
        
        printf $file "%s:\t", $category;
        foreach my $k (1..$n) {
            if($method eq "repto") {
                push (@roll, floor(get_rand($#candidates+1)));
            }
            elsif($method eq "coeur") {
                do { 
                    $a = floor(get_rand($#candidates+1));
                } while ((grep(/^$a$/, @roll))); 
                push (@roll, $a);
            }
        }
        @roll = map {$candidates[$_]} @roll;
        foreach my $r (@roll) { print $file "$r "; } print $file "\n";
    }
    
    close($file);
}


my @roster = read_roster("./roster.txt");
roll("./roll.txt", @roster);
