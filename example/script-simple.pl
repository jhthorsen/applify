#!/usr/bin/perl
use lib 'lib';
use script::simple;

option file => input_file => 'File to read from', 'Makefile.PL';
option dir => output_dir => 'Directory to write files to', '.';
option flag => dry_run => 'Use --no-dry-run to actually do something', required => 1;

app {
    my($self, @extra) = @_;
    my $exit_value = 0;

    print "Will read from: ", $self->input_file, "\n";
    print "Will write files to: ", $self->output_dir, "\n";

    if($self->dry_run) {
        die 'Will not run script';
    }

    return $exit_value;
};
