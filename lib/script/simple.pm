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
use constant GOT_SUB_NAME => eval 'use Sub::Name; 1' ? 1 : 0;
use Getopt::Long ();
use Cwd ();

our $VERSION = '0.01';
my $ANON = 1;

sub __new_sub {
    my($fqn, $code) = @_;
    no strict 'refs';
    if(GOT_SUB_NAME) { *$fqn = Sub::Name::subname($fqn, $code) }
    else { *$fqn = $code }
}

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

Used to define value types for this input.

=over 4

=item bool, flag

=item inc

=item str

=item int

=item num

=item file (TODO)

=item dir (TODO)

=back

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

The script will not start if a required field is omitted.

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
    my $documentation = shift or die 'Usage: option $type => $name => $documentation, ...';
    my($default, @args);

    if(@_ % 2) {
        $default = shift;
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
    my $app = {};
    my $parser = $self->_option_parser;
    my(@options_spec, $application_class);

    for my $option (@{ $self->{'options'} }) {
        push @options_spec, $self->_calculate_option_spec($option);
        $app->{$option->{'name'}} = $option->{'default'}; # set defaults on application object
    }

    $parser->getoptions($app, @options_spec, $self->_default_options);

    if($app->{'help'}) {
        $self->print_help;
        $self->_exit('help');
    }

    $app = $self->_generate_application_class($code)->new($app);

    return $app if(defined wantarray); # $app = do $script_file;
    $self->_exit($app->run(@ARGV));
}

sub _calculate_option_spec {
    my($self, $option) = @_;
    my $spec = $option->{'name'};

    if($option->{'type'} =~ /^(?:bool|flag)/i) { $spec .= '!' }
    elsif($option->{'type'} =~ /^inc/) { $spec .= '+' }
    elsif($option->{'type'} =~ /^str/) { $spec .= '=s' }
    elsif($option->{'type'} =~ /^int/i) { $spec .= '=i' }
    elsif($option->{'type'} =~ /^num/i) { $spec .= '=f' }
    elsif($option->{'type'} =~ /^file/) { $spec .= '=s' } # TODO
    elsif($option->{'type'} =~ /^dir/) { $spec .= '=s' } # TODO
    else { die 'Usage: option {bool|flag|inc|str|int|num|file|dir} ...' }

    return $spec;
}

sub _default_options {
    # TODO Add --man and --version options
    return 'help';
}

sub _generate_application_class {
    my($self, $code) = @_;
    my $application_class = join '::', ref($self), "__ANON__${ANON}__", Cwd::abs_path($self->{'caller'}[1]);
    my @required;

    $ANON++;
    $application_class =~ s![\/]!::!g;
    $application_class =~ s![^\w:]!_!g;
    $application_class =~ s!:::+!::!g;

    eval qq[package $application_class; 1] or die $@;

    {
        no strict 'refs';
        __new_sub "$application_class\::new" => sub { my $class = shift; bless shift, $class };
        __new_sub "$application_class\::script" => sub { $self };
        __new_sub "$application_class\::run" => sub {
            my($app, @extra) = @_;

            if(@required = grep { not defined $app->{$_} } @required) {
                my $required = join ', ', map { "--$_" } @required;
                $app->script->print_help;
                die "Required attribute missing: $required\n";
            }

            return $app->$code(@extra);
        };

        for my $option (@{ $self->{'options'} }) {
            my $name = $option->{'name'};
            my $fqn = join '::', $application_class, $option->{'name'};
            $fqn =~ s!-!_!g;
            __new_sub $fqn => sub { $_[0]->{$name} };
            push @required, $name if($option->{'required'});
        }
    }

    return $application_class;
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
sub _option_parser { $_[0]->{'_option_parser'} ||= Getopt::Long::Parser->new(config => [ qw( no_auto_help no_auto_version pass_through ) ]) }

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

=head2 print_help

    $self->print_help;

Will print L</options> to selected filehandle (STDOUT by default) in
a normalized matter. Example:

    Usage:
       --foo   Foo does this and that
     * --bar   Bar does something else
       --help  Print this help text

=cut

sub print_help {
    my $self = shift;
    my $width = length 'help';

    for my $option (@{ $self->{'options'} }) {
        my $length = length $option->{'name'};
        $width = $length if($width < $length);
    }

    print "Usage:\n";

    for my $option (@{ $self->{'options'} }) {
        printf(" %s --%-${width}s  %s\n",
            $option->{'required'} ? '*' : ' ',
            $option->{'name'},
            $option->{'documentation'},
        );
    }

    printf "   --%-${width}s  %s\n", 'help', 'Print this help text';
    print "\n";

    return $self;
}

sub _exit {
    my($self, $reason) = @_;
    exit 0 if($reason eq 'help');
    exit $reason;
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
    no warnings 'redefine'; # need to allow redefine when loading a new app
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
