package t::Helper;
use strict;
use warnings;
use File::Temp qw{tempdir tempfile};

sub content {
  my ($self, $filename) = @_;
  return '' unless $filename;
  open my $file, '<', $filename or die "Cannot open $filename";
  my $ret = my $content = '';
  while ($ret = $file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
  die qq{Can't read from file "$filename": $!} unless defined $ret;
  return $content;
}

sub new {
  my ($class, $fh) = @_;
  return bless {
      'fh' => $fh, # file handle
      'sp' => 0,   # pointer to stack
      'st' => [],  # stack
  }, $class;
}

sub redirect {
  my ($self, $filename) = @_;
  unless($self->{st}[$self->{sp}]) {
      open $self->{st}[$self->{sp}], '>&', $self->{fh}
        or die "failed to dup";
  }
  close $self->{fh};
  open $self->{fh}, '>', $filename
    or die "failed to open";
  ++$self->{sp};
  $self;
}

sub restore {
  my ($self) = @_;
  if ($self->{st}[$self->{sp}]) {
      close $self->{st}[$self->{sp}];
      delete $self->{st}[$self->{sp}];
  }
  close $self->{fh};
  open $self->{fh}, '>&', $self->{st}[--$self->{sp}] or die "failed to dup";
  $self;
}

sub import {
  my $caller = caller;

  eval <<"HERE" or die $@;
package $caller;
use warnings;
use strict;
use Test::More;
1;
HERE

  {
    no strict 'refs';
    *{"$caller\::run_method"} = sub {
      my ($thing, $method, $ret) = (shift, shift, 0);
      my $tempdir = tempdir 'applify.XXXXX', CLEANUP => 1;
      my ($stderr, $stdout) = map {
        (tempfile 'run_method.XXXXX', DIR => $tempdir, SUFFIX => $_)[1];
      } qw{.err .out};
      my $rs_out = __PACKAGE__->new(*STDOUT)->redirect($stdout);
      my $rs_err = __PACKAGE__->new(*STDERR)->redirect($stderr);
      $ret = eval { $thing->$method(@_) };
      $stdout = $rs_out->restore->content($stdout);
      $stderr = $rs_err->restore->content($stderr);

      return $@ || $stdout, $@ || $stderr, $ret;
    };
  }
}

1;
