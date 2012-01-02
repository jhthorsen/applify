use inc::Module::Install;

name q(script-simple);
all_from q(lib/script/simple.pm);

requires q(File::Basename) => 2.70;
requires q(Getopt::Long) => 2.38;
requires q(Cwd) => 3.31;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=script-simple);
homepage q(http://search.cpan.org/dist/script-simple);
repository q(origin);

# install_script glob('bin/*');
auto_install;
WriteAll;
