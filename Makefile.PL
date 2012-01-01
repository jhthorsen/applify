use inc::Module::Install;

name q(script-simple);
all_from q(lib/script/simple.pm);

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=script-simple);
homepage q(http://search.cpan.org/dist/script-simple);
repository q(origin);

# install_script glob('bin/*');
auto_install;
WriteAll;
