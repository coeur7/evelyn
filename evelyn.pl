#!/usr/bin/perl

BEGIN {
    use strict;
    use warnings;
    use POSIX;
    use Scalar::Util qw(looks_like_number);
    use Data::Dumper;                               # DEBUG
    
    our $EVELYN_version = "2.0.1-stable";
    
    our $verbosity = 1;                             # 0 is silent; other levels undefined rn. TODO: configuration file
    
    our $archetypes_filename  = "./archetypes.txt";
    our $roster_filename      = "./roster.txt";     # roster file containing information pertaining directly to roll/method
    our $roll_filename        = "./roll.txt";       # contains the roll after execution
    our $runlog_filename      = "./runlog.txt";     # contains all the rolls of the run
    our $ratings_filename     = "./ratings.txt";    # contains all the ratings
    our $details_filename     = "";                 # set details, read from roster file
    our $paste_out_filename   = "./team.txt";       # paste output filename
    
    our $max_roll_attempts = 20000;
    
    srand();
}

sub get_rand {
    return floor(rand(shift @_));
}

sub read_roster {
    open(my $file, "<", $roster_filename) || die "[FATAL] Could not read roster information file '".$roster_filename."':".$!;

    my %roster;
    my $category;
    while (my $line = <$file>) {
        if($line =~ m/^\s*details in\s*(.+)\s*\n/g) {
            $details_filename = $1;
        } elsif($line =~ m/^\[\s*(.+)\s*\]\s*\n/g) {
            $category = $1;
        } elsif($line =~ m/^\s*(.+)\s*\n*/g) {
            my @candidates = split(', ', $1);
            $roster{$category} = \@candidates;
        }
    }    
    close($file);
    
    return \%roster;
}

sub read_archetypes {
    open(my $file, "<", $archetypes_filename) || die "[FATAL] Could not read archetypes information file '".$archetypes_filename."':".$!;
    
    my %archetypes, @weighted_array, $current_arch, $method;
    while(my $line = <$file>) {
        if($line =~ m/^\s*archetype\s+(.+?)\s*\n/g) {
            $current_arch = $1;
        } elsif($line =~ m/^\s*method\s+(.+?)\s*\n/g) {
            $method = $1;
        } elsif($line =~ m/^\s*incidence\s+([0-9]+)\s*\n/g) {
            foreach my $k (1..int($1)) { push(@weighted_array, $current_arch); }
        } elsif($line =~ m/^\s*roll\s+([0-9]+)\s*(.+?)\s*\n/g) {
            push(@{$archetypes{$current_arch}}, [$method, $1, [split(", ", $2)]]);
        }
    }
    
    return {"roll_info" => \%archetypes, "random_arch_info" => \@weighted_array};
}

sub roll {
    my $arch_name   = shift @_;
    my $args        = shift @_;
    my %roster      = %{shift @_};
    my $roll_number = 0;
    
    if(open(my $runlog_file, "<", $runlog_filename)) {
        while(my $line = <$runlog_file>) {
            if($line =~ m/^Roll #([0-9]+)/g) { $roll_number = int($1) + 1; }
        }
        close($runlog_file);
    } else { $roll_number = 1; }    
    
    open(my $roll_file, ">", $roll_filename)      || die "[FATAL] Could not create or open roll output file '".$filename."':".$!;
    open(my $runlog_file, ">>", $runlog_filename) || die "[FATAL] Could not create or open run log file '".$runlog_filename."':".$!;
    
    my @print_targets = ($roll_file, $runlog_file);
    if ($verbosity) { push(@print_targets, STDOUT); }
    
    foreach my $target (@print_targets) {
        print $target "-"x80, "\n";
        print $target "Roll #".$roll_number." -- Archetype: ".$arch_name."\n";
    }
    
    foreach my $roll (@{$args}) {
        my $method      = $roll->[0];
        my $n           = $roll->[1];
        my $categories  = $roll->[2];
        
        my @candidates  = ();
        my @category_strings = ();
        foreach my $category (@{$categories}) {
            push(@candidates, @{$roster{$category}});
            push(@category_strings, $category);
        }
        
        for (my $i = 0, $roll_is_valid = 0; $i <= $max_roll_attempts && !$roll_is_valid; $i++) {
            @roll = ();
            foreach my $k (1..$n) {
                if($method eq "repto" || $method eq "asterisk") {
                    push (@roll, get_rand($#candidates+1));
                } elsif ($method eq "coeur" || $method eq "asterisk-nodupl") {
                    my $a;
                    do {
                        $a = get_rand($#candidates+1);
                    } while (grep(/^$a$/, @roll));
                    push(@roll, $a);
                }
            }
            
            @roll = map {$candidates[$_]} @roll;
            if($method eq "asterisk" || $method eq "asterisk-nodupl") {
                if(grep(/\*/, @roll)) { $roll_is_valid = 1; }
            } else { $roll_is_valid = 1; } # always
            if ($i == $max_roll_attempts) { die "Tried ".$max_roll_attempts." rolls; none were valid by the method in use.\n"; }
        }
        
        foreach my $target (@print_targets) {
            printf $target "%-40s", join("/", @category_strings).":";
            foreach my $r(@roll) { print $target "$r, "; }
            print $target "\n";
        }
    }    
  
    foreach my $target (@print_targets) {
        print $target "-"x80, "\n";
    }
    
    close($roll_file);
    close($runlog_file);
    
    return 0;
}

sub export_team {
    if($details_filename eq "") {
        die "[FATAL] No roster details filename supplied (add the line \"details in ___\", replacing the underscores with your filename, to ".$roster_filename.").";
    }
    open(my $details_file, "<", $details_filename) || die "[FATAL] Could not create or open roster details file '".$details_filename."':".$!;
    open(my $out_file, ">", $paste_out_filename) || die "[FATAL] Could not create or open paste output file '".$paste_out_filename."':".$!;
    foreach my $set (@ARGV[1..$#ARGV]) {
        my $mode = 0;
        while(my $line = <$details_file>) {
            if($line =~ m/^\s*(.+?)\s*[(|@].*\n$/g && $1 eq $set) {
                $mode = 1;
            }
            if($mode) { print $out_file $a; }
            if($line =~ m/^\s*\n$/g) {
                $mode = 0;
            }
        }
        seek ($details_file, 0, 0);
    }
    close($details_file);
    close($out_file);
}

sub generate_ratings_file {
    if (-f $ratings_filename) {
        print "[WARNING] Ratings file '".$ratings_filename."' already exists; no action taken.\n(To create a new ratings file, please delete the existing file first.)\n";
        return 0;
    }
    my %roster = %{read_roster()};
    open(my $file, ">", $ratings_filename) || die "[FATAL] Could not create or open ratings file '".$filename."':".$!;
    foreach my $k (keys %roster) {
        foreach my $m (@{$roster{$k}}) {
            print $file $m." 0 0\n";
        }
    }
    close($file);
    return 0;
}

sub rate {
    my $filename    = shift @_;
    my $new_key     = shift @_;
    my $new_val     = shift @_;
    my $mode        = shift @_;
    
    if(! looks_like_number($new_val)) {
        print "[FATAL] '".$new_val."' does not appear to be a numeric value. Aborting.\n";
        return -1;
    }
    
    my %ratings;
    my %ns;
    
    open(my $file, "<", $filename) || die "[FATAL] Could not create or open ratings file '".$filename."':".$!;
    while (my $line = <$file>) {
        $line =~ m/^(.+?)\s+(.+)\s+([0-9]+)\s*\n$/g;
        if(defined $1 && looks_like_number($2) && looks_like_number($3)) {
            $ratings{$1} = $2;
            $ns{$1}      = $3;
        }
    }
    close($file);
    
    if($mode && $ns{$new_key} != 0) {
        $ratings{$new_key} = ($ratings{$new_key} + $new_val / $ns{$new_key}) * $ns{$new_key}/($ns{$new_key}+1); $ns{$new_key}++;  # re-average
    } else { $ratings{$new_key} = $new_val; $ns{$new_key} = ($mode) ? $ns{$new_key} + 1 : 1;}                                     # or set anew
    
    open(my $file, ">", $filename) || die "[FATAL] Could not create or open ratings file '".$filename."':".$!;
    foreach my $k (keys %ratings) {
        print $file $k." ".$ratings{$k}." ".$ns{$k}."\n";
    }
    close($file);
    
    return 0;
}

sub get_random_archetype {
    my $arr = shift @_;
    return $arr->[get_rand($#{$arr})];
}

sub main {
    # Usage help mode
    if($ARGV[0] =~ m/^-[A-Z|a-z|?]*\?/g) { # TODO: archetype roll info (also in readme)
        print "-?                  Usage help\n";
        print "-d SET1 SET2 ...    Generate new team paste from roster details file, using SET1 etc.\n";
        print "-g                  Generate new ratings file for roster\n";
        print "-r  SPECIES RATING  Rate SPECIES with RATING (added and re-averaged)\n";
        print "-r0 SPECIES RATING  Rate SPECIES with RATING (reset rating to new value)\n";
        print "-v                  Print current version\n";
        print "\n(For tech support, you know where to find the esteemed user Coeur7)\n";
        return 0;
    }
    
    # Version information mode
    if($ARGV[0] =~ m/^-[A-Z|a-z|?]*v/g) {
        print "EVELYN version ".$EVELYN_version."\n";
        return 0;
    }
    
    # Export mode
    if($ARGV[0] =~ m/^-d$/g) {
        my $roster = read_roster(); # only to read the details filename. Can't we do that more elegantly?
        export_team();
        return 0;
    }
    
    # Generate ratings file for roster
    if($ARGV[0] =~ m/^-g$/g) {
        generate_ratings_file();
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
    my %archetype_data = %{read_archetypes()};
    my $roster         = read_roster();
    my $arch = defined $ARGV[0] ? $ARGV[0] : get_random_archetype($archetype_data{"random_arch_info"});
    
    roll($arch, $archetype_data{"roll_info"}->{$arch}, $roster);
    return 0;
}

main();
