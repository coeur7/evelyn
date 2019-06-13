#!/usr/bin/perl

BEGIN {
    use strict;
    use warnings;
    use POSIX;
    
    our $EVELYN_version = "1.4";
    
    our $method;
    our $verbosity = 1;                     # 0 is silent; other levels undefined rn. TODO: configuration file
    our $roster_filename  = "./roster.txt"; # roster file containing information pertaining directly to roll/method
    our $roll_filename    = "./roll.txt";   # contains the roll after execution
    our $runlog_filename  = "./runlog.txt"; # contains all the rolls of the run TODO
    our $ratings_filename = "./ratings.txt";# contains all the ratings
    our $details_filename = "";             # set details, read from roster file TODO
    our $paste_out_filename = "./team.txt"; # paste output filename
    our $max_roll_attempts = 20000;
    
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
        my $i = 0;
        
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
            
            $i++;
            if ($i > $max_roll_attempts) { die "Tried ".$max_roll_attempts." rolls; none were valid by the method in use.\n"; }
        } while (!($roll_is_valid));
        
        printf $file "%-32s", $category.":";
        if ($verbosity) { print $category.": "; }
        foreach my $r (@roll) { print $file "$r, "; if ($verbosity) { print "$r, "; } } 
        print $file "\n"; if ($verbosity) { print "\n"; }
    }
    close($file);
    
    return 0;
}

sub rate {
    my $filename    = shift @_;
    my $new_key     = shift @_;
    my $new_val     = shift @_;
    my $mode        = shift @_;
    
    my %ratings;
    my %ns;
    
    open(my $file, "<", $filename) || die "[FATAL] Could not create or open ratings file '".$filename."':".$!;
    while (my $a = <$file>) {
        $a =~ m/^(.+?)\s+(.+)\s+([0-9]+)\s*\n$/g;
        if(defined $1 && defined $2 && defined $3) {
            $ratings{$1} = $2;
            $ns{$1}      = $3;
        }
    }
    close($file);
    
    if($mode && $ns{$new_key} != 0) {
        $ratings{$new_key} = ($ratings{$new_key} + $new_val / $ns{$new_key}) * $ns{$new_key}/($ns{$new_key}+1); $ns{$new_key}++;
    } else { $ratings{$new_key} = $new_val; $ns{$new_key} = ($mode) ? $ns{$new_key} + 1 : 1;}
    
    open(my $file, ">", $filename) || die "[FATAL] Could not create or open ratings file '".$filename."':".$!;
    foreach my $k (keys %ratings) {
        print $file $k." ".$ratings{$k}." ".$ns{$k}."\n";
    }
    close($file);
    
    return 0;
}

sub main {
    # Usage help mode
    if($ARGV[0] =~ m/^-[A-Z|a-z|?]*\?/g) {
        print "-?                  Usage help\n";
        print "-d SET1 SET2 ...    Generate new team paste from roster details file, using SET1 etc.\n";
        print "-g                  Generate new ratings file for roster\n";
        print "-r  SPECIES RATING  Rate SPECIES with RATING (added and averaged)\n";
        print "-r0 SPECIES RATING  Rate SPECIES with RATING (reset rating to new value)\n";
        print "-v                  Print current version\n";
        return 0;
    }
    
    # Version information mode
    if($ARGV[0] =~ m/^-[A-Z|a-z|?]*v/g) {
        print "EVELYN version ".$EVELYN_version."\n";
        return 0;
    }
    
    # Export mode
    if($ARGV[0] =~ m/^-d$/g) {
        my @roster = read_roster($roster_filename);
        open(my $file, "<", $details_filename) || die "[FATAL] Could not create or open roster details file '".$details_filename."':".$!;
        open(my $out_file, ">", $paste_out_filename) || die "[FATAL] Could not create or open paste output file '".$paste_out_filename."':".$!;
        foreach my $set (@ARGV[1..$#ARGV]) {
            my $mode = 0;
            while(my $a = <$file>) {
                if($a =~ m/^\s*(.+?)\s*[(|@].*\n$/g && $1 eq $set) {
                    $mode = 1;
                }
                if($mode) { print $out_file $a; }
                if($a =~ m/^\s*\n$/g) {
                    $mode = 0;
                }
            }
            seek ($file, 0, 0);
        }
        return 0;
    }
    
    # Generate ratings file for roster
    if($ARGV[0] =~ m/^-g$/g) {
        if (-f $ratings_filename) {
            print "[WARNING] Ratings file '".$ratings_filename."' already exists; please manually delete it and retry.\n";
            return 0;
        }
        my @roster = read_roster($roster_filename);
        open(my $file, ">", $ratings_filename) || die "[FATAL] Could not create or open ratings file '".$filename."':".$!;
        foreach my $group (@roster) {
            foreach my $k (@{$group->[2]}) {
                print $file $k." 0 0\n";
            }
        }
        close($file);
        return 0;
    }
    
    # Rating mode
    if($ARGV[0] =~ m/^-r0$/g) {
        rate($ratings_filename, $ARGV[1], $ARGV[2], 0);
        return 0;
    }
    if($ARGV[0] =~ m/^-r$/g) {
        rate($ratings_filename, $ARGV[1], $ARGV[2], 1);
        return 0;
    }

    # Roll mode
    my @roster = read_roster($roster_filename);
    roll($roll_filename, @roster);
    
    return 0;
}

main();
