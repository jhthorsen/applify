use warnings;
use strict;
use Test::More;
use Data::Dumper;
my $app = eval <<"HERE" or die $@;
use Applify;
use Mojo::File 'path';
option dir => directory => 'dir', class => 'Mojo::File';
option file => config_file => 'configuration', class => 'Mojo::File';
option file => file_list => 'files to process', n_of => '\@', class => 'Mojo::File';
option file => output => 'output file', default => 'example/output.txt', class => 'Mojo::File';
option str => check => 'simple';
app {};
HERE

my $script = $app->_script;

{
  local @ARGV = ('--directory', '.');
  my $app = $script->app;
  isa_ok $app->directory, 'Mojo::File', 'directory option';
  isa_ok $app->output, 'Mojo::File', 'default';
  is $app->output, 'example/output.txt', 'output file default';
}

{
  local @ARGV = ('--directory', 'example');
  my $app = $script->app;
  isa_ok $app->directory, 'Mojo::File', 'directory option';
  my $files = $app->directory->list;
  isa_ok $files, 'Mojo::Collection';
  my @set = @$files;
  is_deeply(\@set, [map { "example/$_" } qw{fatpack.sh moo.pl test1.pl}], 'file list');
}

{
  local @ARGV = ('--config', 'example/moo.pl');
  my $app = $script->app;
  isa_ok $app->config_file, 'Mojo::File', 'config option';
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
  isa_ok $_, 'Mojo::File', 'file is a Mojo::File' for @{$app->file_list};
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
