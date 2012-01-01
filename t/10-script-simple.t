use warnings;
use strict;
use lib qw(lib);
use Test::More;
use script::simple ();

plan tests => 26;

{
    my $app = eval q[use script::simple; app {}] or BAIL_OUT $@;
    my $script = $app->script;

    isa_ok($script, 'script::simple');
    can_ok($script, qw/
        option app
        caller options
        new print_help import
    /);

    is($script->caller->[0], 'main', 'called from main::');
    isa_ok($script->_option_parser, 'Getopt::Long::Parser');

    {
        local $TODO = 'need to define config for Getopt::Long';
        is_deeply($script->_option_parser->{'settings'}, [qw/ no_auto_help pass_through /], 'Getopt::Long has correct config');
    }

    eval { $script->option(undef) };
    like($@, qr{^Usage:.*type =>}, 'option() require type');
    eval { $script->option(str => undef) };
    like($@, qr{^Usage:.*name =>}, 'option() require name');
    eval { $script->option(str => foo => undef) };
    like($@, qr{^Usage:.*documentation}, 'option() require documentation');

    $script->option(str => foo_bar => 'Foo can something');
    is_deeply($script->options, [
        {
            default => undef,
            type => 'str',
            name => 'foo-bar',
            documentation => 'Foo can something',
        }
    ], 'add foo as option');

    $script->option(str => foo_2 => 'foo_2 can something else', 42);
    is($script->options->[1]{'default'}, 42, 'foo_2 has default value');

    $script->option(str => foo_3 => 'foo_3 can also something', 123, required => 1);
    is($script->options->[2]{'default'}, 123, 'foo_3 has default value');

    {
        local $TODO = 'need to implement required => 1';
        is($script->options->[2]{'required'}, 1, 'foo_3 is required');
    }

    is($script->_calculate_option_spec({ name => 'a_b', type => 'foo' }), 'a_b=s', 'a_b=s');
    is($script->_calculate_option_spec({ name => 'a_b', type => 'bool' }), 'a_b!', 'a_b!');
    is($script->_calculate_option_spec({ name => 'a_b', type => 'flag' }), 'a_b!', 'a_b!');
    is($script->_calculate_option_spec({ name => 'a_b', type => 'inc' }), 'a_b+', 'a_b+');
    is($script->_calculate_option_spec({ name => 'a_b', type => 'int' }), 'a_b=i', 'a_b=i');
    is($script->_calculate_option_spec({ name => 'a_b', type => 'num' }), 'a_b=f', 'a_b=f');

    {
        local $TODO = 'Add proper support for file/dir';
        is($script->_calculate_option_spec({ name => 'a_b', type => 'file' }), 'a_b=s', 'a_b=s');
        is($script->_calculate_option_spec({ name => 'a_b', type => 'dir' }), 'a_b=s', 'a_b=s');
    }

    {
        local $TODO = 'Add support for --version and --man';
        is_deeply([$script->_default_options], [qw/ help /], 'default options');
    }

    my $application_class = $script->_generate_application_class(sub{});
    like($application_class, qr{^script::simple::__ANON__2__::}, 'generated application class');
    can_ok($application_class, qw/
        new run script
        foo_bar foo_2 foo_3
    /);

    is((run_method($script, 'print_help'))[0], <<'    HELP', 'print_help()');
Usage:
   --foo-bar  Foo can something
   --foo-2    foo_2 can something else
 * --foo-3    foo_3 can also something
   --help     Print this help text

    HELP
}

{
    my $app = do 'example/script-simple.pl';
    isa_ok($app->script, 'script::simple');
    can_ok($app, qw/ input_file output_dir dry_run /);
}

sub run_method {
    my($thing, $method, @args) = @_;
    local *STDOUT;
    local *STDERR;
    my $stdout = '';
    my $stderr = '';
    open STDOUT, '>', \$stdout;
    open STDERR, '>', \$stderr;
    return $stdout, $stderr, $thing->$method(@args);
}
