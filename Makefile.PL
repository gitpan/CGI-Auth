use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Auth',
    'VERSION_FROM'	=> 'Auth.pm', # finds $VERSION
    'PREREQ_PM'		=> {CGI => 2.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	  => 'Simple session-based password authentication for CGI applications',
       AUTHOR     => 'Chad Wallace <cmdrwalrus@canada.com>') : ()),
);
