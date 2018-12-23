use strict;
use warnings;
use File::Temp ();
use File::Spec ();
use Symbol 'delete_package';
use lib '.';
use t::Helper;
no lib '.';

my $file = __FILE__;
my $code = <<"HERE";
package main;
use Applify;
sub is_par_packed { Applify::APPLIFY_PAR_PACKED }
documentation '$file';
app { 0 };
HERE

{
  my ($out, $err, $return, $exited) =
    build_app($code, \&code_isnt_par_packed, '--help');
  like $out, qr/FooBarBaz/, 'help included - this file';
  is $err, '', 'no error';
  is $return->run, 0, 'returned zero';
  is $exited, 1, 'print_help';
}

$file = __FILE__;
$file =~ s/^t/script/; ## simulate PAR::Packer __FILE__
$code = <<"HERE";
package main;
use Applify;
sub is_par_packed { Applify::APPLIFY_PAR_PACKED }
documentation '$file';
app { 0 };
HERE

{
  my ($tmp) = build_par_temp(\&write_pod, $file);
  my ($out, $err, $return, $exited) =
    mock_par_packed_app($tmp, $code, \&code_is_par_packed, '--help');
  like $out, qr/alternate/, 'help is included';
  is $err, '', 'no error';
  is $return->run, 0, 'returned zero';
  is $exited, 1, 'print_help';
}

{
  local $ENV{PERLDOC} = '-t';
  my ($tmp) = build_par_temp(\&write_pod, $file);
  my ($out, $err, $return, $exited) =
    mock_par_packed_app($tmp, $code, \&code_is_par_packed, '--man');
  like $out, qr/^SYNOPSIS/, 'pod formatting';
  like $out, qr/alternate/, 'pod formatting';
  is $err, '', 'no error';
  is $return->run, 0, 'returned zero';
  is $exited, 1, 'print_help';
}

done_testing;


sub build_app {
  my ($app_code, $sub_test, $exited) = (shift, shift, 0);

  local %INC = %INC;
  delete_package 'Applify';
  delete_package 'Sub::Name';

  local *CORE::GLOBAL::exit = sub (;$) { $exited = 1; };
  ## eval bakes in exit as overridden above
  my $app = eval "$app_code" or die $@;
  subtest "app" => sub {
    is $exited, 0, 'no exit yet';
    $sub_test->($app);
  };

  local @ARGV = @_;
  my ($out, $err, $return) = run_method($app->_script, 'app');

  *CORE::GLOBAL::exit = *CORE::exit;

  return ($out, $err, $return, $exited);
}

sub build_par_temp {
  my $code = shift || sub {};
  my $temp = File::Temp::tempdir('par-packing.t.XXXXX', CLEANUP => 1);
  ok mkdir File::Spec->catdir($temp, 'inc');
  ok mkdir File::Spec->catdir($temp, 'inc', 'script');
  $code->($temp, @_);
  return $temp;
}

sub code_is_par_packed {
  my $app = shift;
  is $app->is_par_packed, 1, 'code considered par packed';
}

sub code_isnt_par_packed {
  my $app = shift;
  is $app->is_par_packed, 0, 'not par packed';
}

sub mock_par_packed_app {
  my ($par_temp) = (shift);

  local $ENV{PAR_0} = 1;
  local $ENV{PAR_TEMP} = $par_temp;
  local $INC{'PAR/Dist.pm'} = 1;

  return build_app(@_);
}

sub write_pod {
  my ($par_temp, $file) = (shift, shift);
  # generate alternate pod in temp file to be found by "packed" script
  my @pod = ("=encoding utf8", "=head1 SYNOPSIS", "An alternate file", "=cut");
  my $pod_file = File::Spec->catdir($par_temp, 'inc', $file);
  open my $copy, '>', $pod_file;
  say $copy "$_\n" for @pod;
  close $copy;
}

=encoding utf8

=head1 NAME

par-packing.t

=head1 SYNOPSIS

FooBarBaz

=cut
