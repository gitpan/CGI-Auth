#!/usr/bin/perl -w    

# $Id: 1.t,v 1.4 2003/12/14 01:25:55 cmdrwalrus Exp $

use Test::Simple tests => 4;

require CGI::Auth;

my @files;

# Need to create auth and sess dirs and user data file.
mkdir 'auth';
mkdir 'auth/sess';
if ( open( USERDAT, '> auth/user.dat' ) )
{
	push @files, 'auth/user.dat';
	print USERDAT <<'USERDAT';
testing:HpPZfni0asUwwHpzbAVdwY50uY
USERDAT
	close( USERDAT );
}


# Attempt to create a CGI::Auth object.
my $auth = CGI::Auth->new( {
	-authdir		=> 'auth',
	-formaction		=> 'myscript.pl',
	-authfields		=> [
		{id => 'user', display => 'User Name', hidden => 0, required => 1},
		{id => 'pw', display => 'Password', hidden => 1, required => 1},
	],
} );

# Ensure that an object was created OK.
ok( defined $auth, 'object defined' );							# Object exists,
ok( $auth->isa( 'CGI::Auth' ), 'object is the right class' );	# and it's of the right class.


my $test;

# Now we need to create a check script to verify that CGI::Auth is going to 
# print the login page.
if ( open( CHECK, '> check.pl' ) )
{
	push @files, 'check.pl';
	print CHECK <<'CHECK';
require CGI::Auth; 

my $auth = CGI::Auth->new({
	-authdir                => 'auth',
	-formaction             => "myscript.pl",
	-authfields             => [
		{id => 'user', display => 'User Name', hidden => 0, required => 1},
		{id => 'pw', display => 'Password', hidden => 1, required => 1},
	],
});
$auth->check;
CHECK
	close( CHECK );

	# Verify that it printed at least a Content-type.
	$test = ( qx/perl -w check.pl/ =~ m/^Content-Type:/i );
}
else
{
	undef $test;
}
ok( $test, "check test script" );


# Now let's try to log in.
if ( open( LOGIN, '> login.pl' ) )
{
	push @files, 'login.pl';
	print LOGIN <<'LOGIN';
require CGI::Auth; 

my $auth = CGI::Auth->new({
	-authdir                => 'auth',
	-formaction             => "myscript.pl",
	-authfields             => [
		{id => 'user', display => 'User Name', hidden => 0, required => 1},
		{id => 'pw', display => 'Password', hidden => 1, required => 1},
	],
});
$auth->check;

print $auth->data( 'sess_file' );
LOGIN
	close( LOGIN );

	qx/perl -w login.pl auth_user=testing auth_pw=testing auth_submit=1/ =~ m/(\w+)/;
	my $sessfile = $1;
	if ( $sessfile && open( SESSFILE, "< auth/sess/$sessfile" ) )
	{
		push @files, "auth/sess/$sessfile";
		my $field0 = <SESSFILE>;
		close( SESSFILE );

		# This test is successful if the username shows up in the session file.
		$test = ( $field0 =~ m/^testing/ );
	}
	else
	{
		undef $test;
	}
}
else
{
	undef $test;
}
ok( $test, "login test script" );

# Now let's clean up the mess we've made.
for ( @files )
{
	unlink if ( -f );
}
rmdir 'auth/sess' if ( -d 'auth/sess' );
rmdir 'auth' if ( -d 'auth' );
