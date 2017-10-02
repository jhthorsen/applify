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
  my ($app, $exited, $err, $stdout, $stderr) =
    eval_script($code, 'log', '--age', '2d', '--save');
  is $exited, 0, 'did not exit';
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
  my ($app, $exited, $err, $stdout, $stderr) =
    eval_script($code, 'logs', '--long', 'prefix');
  ok $exited, 'exit was called';
  like $stdout, qr/Usage:/, 'printed help';
  isa_ok $app, 'HASH', 'object as exit did not happen';
  is $app->save, undef, 'not set';
}

sub eval_script {
    my ($code, @args) = @_;
    local @ARGV = @args;
    my ($exited, $app) = (0);
    local *STDOUT;
    local *STDERR;
    my $stdout = '';
    my $stderr = '';
    open STDOUT, '>', \$stdout;
    open STDERR, '>', \$stderr;

    {
      local *CORE::GLOBAL::exit = sub (;$) { $exited = 1; };
      $app = eval "$code";
      # no warnings 'once' and https://stackoverflow.com/a/25376064
      *CORE::GLOBAL::exit = *CORE::exit;
    }
    return ($app, $exited, $@, $stdout, $stderr);
}

done_testing();
