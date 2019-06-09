#!/usr/bin/perl

BEGIN {
    use strict;
    use warnings;
    use POSIX;
    
    our $method;
    our $verbosity = 1;                     # 0 is silent; other levels undefined rn. TODO: configuration file
    our $roster_filename  = "./roster.txt"; # roster file containing information pertaining directly to roll/method
    our $output_filename  = "./roll.txt";   # contains the roll after execution
    our $runlog_filename  = "./runlog.txt"; # contains all the rolls of the run TODO
    our $details_filename = "";             # set details, read from roster file TODO
    
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
        if($a =~ m/^\s*method\s*(.+)\s*\n/g) {
            $method = $1;
        } elsif($a =~ m/^\s*details in\s*(.+)\s*\n/g) {
            $details_filename = $1;
        } elsif($a =~ m/^\[\s*(.+)\s*\]\s*\n/g) {
            $category = $1;
        } elsif($a =~ m/^\s*([0-9])+\s*\n/g) {
            $n = $1;
        } elsif($a =~ m/^\s*(.+)\s*\n*/g) {
            my @candidates = split(', ', $1);
            push(@roster, [$category, $n, \@candidates]);
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
    foreach $group (@roster) {
        my $category = $group->[0];
        my $n        = $group->[1];
        my @candidates = @{$group->[2]};
        my @roll;
        my $roll_is_valid = 0;
        
        printf $file "%-32s", $category.":";
        if ($verbosity) { print $category.": "; }
        
        do {
            @roll = ();
            foreach my $k (1..$n) {
                if($method eq "repto" || $method eq "asterisk") {
                    push (@roll, floor(get_rand($#candidates+1)));
                }
                elsif($method eq "coeur" || $method eq "asterisk-nodupl") {
                    do { 
                        $a = floor(get_rand($#candidates+1));
                    } while ((grep(/^$a$/, @roll))); 
                    push (@roll, $a);
                }
            }
        
            @roll = map {$candidates[$_]} @roll;
            if($method eq "asterisk" || $method eq "asterisk-nodupl") {
                if (grep(/\*/, @roll)) { $roll_is_valid = 1; }
            } else { $roll_is_valid = 1; } # always
        } while (!($roll_is_valid));
        
        foreach my $r (@roll) { print $file "$r, "; if ($verbosity) { print "$r, "; } } 
        print $file "\n"; if ($verbosity) { print "\n"; }
    }
    close($file);
}

sub main {
    my @roster = read_roster("./roster.txt");
    roll("./roll.txt", @roster);
    
    return 0;
}

main();
