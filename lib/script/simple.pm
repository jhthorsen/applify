package script::simple;

=head1 NAME

script::simple - Write object oriented scripts with ease

=head1 VERSION

0.01

=head1 DESCRIPTION

This module should keep all the noise away and let you write scripts
very easily. These scripts can even be unittested even though they
are define directly in the script file and not in a module.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use script::simple;

    option file => input_file => 'File to read from';
    option dir => output_dir => 'Directory to write files to';
    option flag => dry_run => 'Use --no-dry-run to actually do something', 1;

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

=cut

use strict;
use warnings;
use Getopt::Long ();
use Cwd ();

our $VERSION = '0.01';
my $ANON = 1;

=head1 EXPORTED FUNCTIONS

=head2 option

    option $type => $name => $documentation;
    option $type => $name => $documentation, $default;
    option $type => $name => $documentation, $default, @args;

This function is used to define options which can be given to this
application. See L</SYNOPSIS> for example code. This function can also be
called as a method on C<$self>.

=over 4

=item * $type

Used to define value types for this input. (TODO)

=item * $name

The name of an application switch. This name will also be used as
accessor name inside the application. Example:

    # define an application switch:
    option file => some_file => '...';

    # call the application from command line:
    > myapp.pl --some-file /foo/bar

    # run the application code:
    app {
        my $self = shift;
        print $self->some_file # prints "/foo/bar"
        return 0;
    };

=item * C<$documentation>

Used as description text when printing the usage text.

=item * C<@args>

=over 4

=item * C<required>

TODO

=item * Other

Any other L<Moose> attribute argument may/will be supported in
future release.

=back

=back

=cut

sub option {
    my $self = shift;
    my $type = shift or die 'Usage: option $type => ...';
    my $name = shift or die 'Usage: option $type => $name => ...';
    my($documentation, $default, @args);

    if(@_ <= 2) {
        ($documentation, $default) = @_;
    }
    elsif(@_ % 2) {
        $documentation = shift;
        @args = @_;
    }
    else {
        @args = @_;
    }

    $name =~ s!_!-!g;

    push @{ $self->{'options'} }, {
        default => $default,
        @args,
        type => $type,
        name => $name,
        documentation => $documentation,
    };
    
    return $self;
}

=head2 app

    app CODE;

This function will define the code block which is called when the application
is started. See L</SYNOPSIS> for example code. This function can also be
called as a method on C<$self>.

IMPORTANT: This function must be the last function called in the script file
for unittests to work. Reason for this is that this function runs the
application in void context (started from command line), but returns the
application object in list/scalar context (from L<perlfunc/do>).

=cut

sub app {
    my($self, $code) = @_;
    my $parser = $self->_getopt_parser;
    my $app = {};
    my @options_spec;

    for my $option (@{ $self->{'options'} }) {
        push @options_spec, $self->_calculate_option_spec($option);
        $app->{$option->{'name'}} = $option->{'default'}; # set defaults on application object
    }

    # add default options
    # TODO: --man and --version
    push @options_spec, 'help';

    $parser->getoptions($app, @options_spec);
    $app->{'script'} = $self;

    if($app->{'help'}) {
        $self->_print_help;
        $self->_exit('help');
    }

    bless $app, $self->_generate_application_class($code);

    if(defined wantarray) { # $app = do $script_file;
        return $app;
    }
    else { # perl $script_file;
        $app->run(@ARGV); # TODO: Handle exceptions
    }
}

sub _calculate_option_spec {
    my($self, $option) = @_;
    my $spec = $option->{'name'};

    if($option->{'type'} =~ /^(?:bool|flag)/i) { $spec .= '!' }
    elsif($option->{'type'} =~ /^inc/) { $spec .= '+' }
    elsif($option->{'type'} =~ /^int/i) { $spec .= '=i' }
    elsif($option->{'type'} =~ /^num/i) { $spec .= '=f' }
    elsif($option->{'type'} =~ /^file/) { $spec .= '=s' } # TODO
    elsif($option->{'type'} =~ /^dir/) { $spec .= '=s' } # TODO
    else { $spec .= '=s' }

    return $spec;
}

sub _generate_application_class {
    my($self, $code) = @_;
    my $application_class = join '::', ref($self), "__ANON__${ANON}__", Cwd::abs_path($self->{'caller'}[1]);

    $ANON++;
    $application_class =~ s![\/]!::!g;
    $application_class =~ s![^\w:]!_!g;
    $application_class =~ s!:::+!::!g;

    eval qq[
        package $application_class;
        use strict;
        use warnings;
        1;
    ] or die $@;

    {
        no strict 'refs';
        *{ "$application_class\::run" } = $code;
        *{ "$application_class\::script" } = sub { $_[0]->{'script'} };

        for my $option (@{ $self->{'options'} }) {
            my $name = $option->{'name'};
            my $fqn = join '::', $application_class, $option->{'name'};
            $fqn =~ s!-!_!g;
            *$fqn = sub { $_[0]->{$name} };
        }
    }

    return $application_class;
}

sub _print_help {
    my $self = shift;
    my $width = length 'help';

    for my $option (@{ $self->{'options'} }) {
        my $length = length $option->{'name'};
        $width = $length if($width < $length);
    }

    print "Usage:\n";

    for my $option (@{ $self->{'options'} }) {
        printf(" %s --%s  %s\n",
            $option->{'required'} ? '*' : ' ',
            $option->{'name'},
            $option->{'documentation'},
        );
    }

    printf "   --%s  %s\n", 'help', 'Print this help text';
    print "\n";

    return $self;
}

sub _exit {
    my($self, $reason) = @_;
    # TODO: Use $reason
    exit 0;
}

=head1 ATTRIBUTES

=head2 options

    $array_ref = $self->options;

Holds the application options given to L</option>.

=head2 caller

    $array_ref = $self->caller;

Holds information about the caller script file/namespace. See also
L<perlfunc/caller>.

=cut

sub caller { $_[0]->{'caller'} }
sub options { $_[0]->{'options'} }
sub _getopt_parser { Getopt::Long::Parser->new(config => [ qw( no_auto_help pass_through ) ]) }

=head1 METHODS

=head2 new

    $self = $class->new({ caller => $array_ref, ... });

Object constructor. Creates a new object representing the script meta
information.

=cut

sub new {
    my($class, $args) = @_;
    my $self = bless $args, $class;

    $self->{'options'} ||= [];
    $self->{'caller'} or die 'Usage: $self->new({ caller => [...], ... })';

    return $self;
}

=head2 import

Will export the functions listed under L</EXPORTED FUNCTIONS>. The functions
will act on a L<script::simple> object created by this method.

=cut

sub import {
    my $class = shift;
    my @caller = CORE::caller(0);
    my $self = $class->new({ caller => \@caller });

    strict->import;
    warnings->import;

    no strict 'refs';
    *{"$caller[0]\::app"} = sub (&) { $self->app(@_) };
    *{"$caller[0]\::option"} = sub { $self->option(@_) };
}

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen

=cut

1;
