#!/usr/bin/perl
use lib 'lib';
use Applify;

option file => input_file => 'File to read from', 'Makefile.PL';
option dir => output_dir => 'Directory to write files to', '.';
option flag => dry_run => 'Use --no-dry-run to actually do something', required => 1;

version 1.23;
documentation __FILE__;

sub app::generate_exit_value {
    return int rand 100;
}

app {
    my($self, @extra) = @_;
    my $exit_value = 0;

    print "Extra arguments: @extra\n" if(@extra);
    print "Will read from: ", $self->input_file, "\n";
    print "Will write files to: ", $self->output_dir, "\n";

    if($self->dry_run) {
        die 'Will not run script';
    }

    return $self->generate_exit_value;
};

=head1 NAME

test1.pl - Example script

=head1 DESCRIPTION

This script is just an example script...

=head1 AUTHOR

See L<Applify>.

=cut
