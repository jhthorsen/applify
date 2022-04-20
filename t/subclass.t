use strict;
use warnings;
use Test::More;

{ package MyApplify;

  use parent 'Applify';

  sub _app_run {
      my ($app, @extra) = @_;
      $app->foo(22);
      $app->SUPER::_app_run( @extra );
  }

}

my $app = eval q[
  use v5.10;
  BEGIN {
    MyApplify->import;
  }
  option int => foo => 'foo';
  app { return 0; };
];

ok $app, 'app was constructed'
  or diag $@;
$app->run;
is $app->foo, 22, 'foo() returns 22' if $app;

done_testing;
