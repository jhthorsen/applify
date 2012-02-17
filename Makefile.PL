use inc::Module::Install;

name q(Applify);
all_from q(lib/Applify.pm);

requires q(File::Basename) => 2.70;
requires q(Getopt::Long) => 2.38;
requires q(Cwd) => 3.31;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=Applify);
homepage q(http://metacpan.org/dist/Applify);
repository q(https://github.com/jhthorsen/applify.git);

# install_script glob('bin/*');
auto_install;
WriteAll;
