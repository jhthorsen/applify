use strict;
use warnings;

package MyListing;
our $VERSION = 1;
package MyLogging;
our $VERSION = 1;

package main;
use Test::More;
use lib '.';
use t::Helper;

my $code = <<"HERE";
use Applify;
option str => input_file => 'input';
option flag => save => 'save work';
subcommand list => 'provide a listing' => sub {
  extends 'MyLisitng';
  option str => long => 'long list';
};
subcommand log => 'provide a log' => sub {
  extends 'MyLogging';
  option str => age => 'age of log', required => 1;
};
app {};
HERE

{
  my $app = eval_script($code, 'log', '--age', '2d', '--save');
  isa_ok $app, 'MyLogging', 'correct inheritance';
  is $app->age, '2d', 'age option set';
  is $app->save, 1, 'global option set';
  my $script = $app->_script;
  is $script->subcommand, 'log', 'access the subcommand being run';
  is + (run_method($script, 'print_help'))[0], <<'HERE', 'print_help()';
Usage:

    subcommand.t [command] [options]

commands:
    list  provide a listing
    log   provide a log

options:
   --input-file  input
   --save        save work
 * --age         age of log

   --help        Print this help text

HERE

}


{
  my $app = eval_script($code, 'logs', '--long', 'prefix');
  isa_ok $app, 'HASH', 'object as exit did not happen';
  is $app->save, undef, 'not set';
  my $script = $app->_script;
  is $script->subcommand, undef, 'no matching subcommand';
  is + (run_method($script, 'print_help'))[0], <<'HERE', 'print_help()';
Usage:

    subcommand.t [command] [options]

commands:
    list  provide a listing
    log   provide a log

options:
   --input-file  input
   --save        save work

   --help        Print this help text

HERE

}

sub eval_script {
    my ($code, @args) = @_;
    local @ARGV = @args;

    my $app = eval "$code" or die $@;

    return $app;
}

done_testing();
