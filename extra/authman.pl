#!/usr/bin/perl

require CGI::Auth;
require AuthCfg;

$AuthCfg::authcfg->{-admin} = 1;

my $userfile = $AuthCfg::authcfg->{-authdir} . "/user.dat";
unless ( -f $userfile )
{
	open USERDAT, "> $userfile" and close USERDAT;
}

my $auth = new CGI::Auth( $AuthCfg::authcfg ) or die "CGI::Auth error";

if ($ARGV[0] eq 'prune')
{
	print "Pruning session file directory...\n";
	print $auth->prune, " stale session files deleted.\n";
	exit;
}

my $menutext = <<MENU;
Acquisitions Database Authorization Manager

Select one of the following options:

A - Add a user.
L - List users.
V - View a user.
D - Delete a user.
P - Prune session files.
Q - Quit.

MENU

do
{
	print $menutext, "Option: ";
	$option = <STDIN>;

	print "\n";
	if ($option =~ /^a/i)
	{
		my ($un, $pw, $confirm);
		
		UN: {
			print "User name to add: ";
			$un = <STDIN>;
			chomp $un; chomp $un;		# Two chomps because of the \r\n in Windows
			if ($un =~ /\|/)
			{
				print "The user name cannot contain the '|' character.\n";
				redo UN;
			}
		}
			
		PW: {
			print "Password for user $un (16 characters or less): ";
			$pw = <STDIN>;
			chomp $pw; chomp $pw;		# Two chomps because of the \r\n in Windows
			if (length $pw > 16)
			{
				print "Password must be 16 characters or less.\n";
				redo PW;
			}
		}

		print "Adding user '$un' with password '$pw'.\n";
		$auth->adduser($un, $pw);
	}
	elsif ($option =~ /^l/i)
	{
		print "Users currently in the userbase:\n\n";
		$auth->listusers;
	}
	elsif ($option =~ /^v/i)
	{
		my $un;
		print "User name to view: ";
		$un = <STDIN>;
		chomp $un; chomp $un;		# Two chomps because of the \r\n in Windows

		$auth->viewuser($un);
	}
	elsif ($option =~ /^d/i)
	{
		my $un;

		print "User name to delete: ";
		$un = <STDIN>;
		chomp $un; chomp $un;		# Two chomps because of the \r\n in Windows

		$auth->deluser($un);
	}
	elsif ($option =~ /^p/i)
	{
		print "Pruning session file directory...\n";
		print $auth->prune, " stale session files deleted.\n";
	}

	print "\n";
} while ($option !~ /^q/i);
