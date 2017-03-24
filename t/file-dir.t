package TestApp::File;
use overload
  '""'     => sub { ${$_[0]} },
  fallback => 1;
sub new { return bless \(pop), 'TestApp::File'; }

package main;
use warnings;
use strict;
use Test::More;

my $app = eval <<"HERE" or die $@;
package TestApp;
use Applify;
option dir => directory => 'dir', class => 'TestApp::File';
option file => config_file => 'configuration', class => 'TestApp::File';
option file => file_list => 'files to process', n_of => '\@', class => 'TestApp::File';
option file => output => 'output file', default => 'example/output.txt', class => 'TestApp::File';
option str => check => 'simple';
app {};
HERE

my $script = $app->_script;

{
  local @ARGV = ('--directory', '.');
  my $app = $script->app;
  isa_ok $app->directory, 'TestApp::File', 'directory option';
  isa_ok $app->output, 'TestApp::File', 'default';
  is $app->output, 'example/output.txt', 'output file default';
}

{
  local @ARGV = ('--directory', 'example');
  my $app = $script->app;
  isa_ok $app->directory, 'TestApp::File', 'directory option';
  ok -d $app->directory, 'directory exists and is a directory';
}

{
  local @ARGV = ('--config', 'example/moo.pl');
  my $app = $script->app;
  isa_ok $app->config_file, 'TestApp::File', 'config option';
  ok -e $app->config_file, '"config file" exists';
}

{
  local @ARGV = ('--file', 'example/moo.pl');
  my $app = $script->app;
  isa_ok $app->file_list, 'ARRAY', 'file list option';
  is @{$app->file_list}, 1, 'correct # of files';
  my ($first) = @{$app->file_list};
  ok -e $first, 'file exists';
}

{
  local @ARGV = ('--file', 'example/moo.pl', '--file', 'example/test1.pl');
  my $app = $script->app;
  isa_ok $app->file_list, 'ARRAY', 'file list option ';
  ok -e $_, 'file exists' for @{$app->file_list};
  is @{$app->file_list}, 2, 'correct # of files';
  isa_ok $_, 'TestApp::File', 'file is a TestApp::File' for @{$app->file_list};
}


is_deeply(run('--directory' => 'example', '--check' => 'this'),  ['example', undef], 'undef');

is_deeply(run('--directory' => 'example', '--config' => 'test'), ['example', 'test'], 'this test');

is_deeply(run('--directory' => 'example', '--file' => 'test1', '--file' => 'test2'), ['example', undef], 'this test');

done_testing;

sub run {
  local @ARGV = @_;
  my $app = $script->app;
  return [$app->directory, $app->config_file];
}
