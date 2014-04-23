use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Applify',
  ABSTRACT_FROM => 'lib/Applify.pm',
  VERSION_FROM => 'lib/Applify.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Cwd' => '3.31',
    'File::Basename' => '2.70',
    'Getopt::Long' => '2.38',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.98',
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Applify',
      bugtracker => 'https://github.com/jhthorsen/applify/issues',
      repository => 'https://github.com/jhthorsen/applify',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
