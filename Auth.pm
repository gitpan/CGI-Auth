package CGI::Auth;

=pod

=head1 NAME

CGI::Auth - Simple session-based password authentication for CGI applications

=head1 SYNOPSIS

    require CGI::Auth;

    my $auth = new CGI::Auth({
        -authdir		=> 'auth',
        -formaction		=> "myscript.pl",
        -authfields		=> [
            {id => 'user', display => 'User Name', hidden => 0, required => 1},
            {id => 'pw', display => 'Password', hidden => 1, required => 1},
        ],
    });
    $auth->check;

=head1 DESCRIPTION

C<CGI::Auth> provides password authentication for web-based applications.  It 
uses server-based session files which are referred to by a parameter in all 
links and forms inside the scripts guarded by C<CGI::Auth>.

At the beginning of each script using Auth.pm, an C<CGI::Auth> object should be 
created and its C<check> method called.  When this happens, C<check> checks for 
a 'session_file' CGI parameter.  If that parameter exists and has a matching 
session file in the session directory, C<check> returns, and the rest of the 
script can execute.

If the session file parameter or the file itself doesn't exist, C<check> 
presents the user with a login form and exits the script.  The login form will 
then be submitted to the same script (specified in C<-formaction>).  When 
C<check> is called this time, it verifies the user's login information in the 
userfile, creates a session file and provides the session file parameter to the 
rest of the script.

=head1 CREATING AND CONFIGURING

Before anything can be done with Auth.pm, an C<Auth> object must be created:

    my $auth = new Auth(\%options);

The C<new> method creates and configures an C<Auth> object using parameters 
that are passed via a hash reference that can/should contain the following 
items (optional ones are indicated):

=over 4

=item C<-cgi>

I<(optional)>

This parameter provides Auth with a CGI object reference so that the extra 
overhead of creating another object can be avoided.  If your script is going to 
use CGI.pm, it is most efficient to create the CGI object and pass it to Auth, 
rather than both your script and Auth having to create separate objects.

=item C<-admin>

I<(optional if C<-formaction> given)>

This parameter should be used by command-line utilities that perform 
administration of the user database.  If Auth is given this parameter, it will 
only allow command-line execution (execution from CGI will be aborted).

=item C<-authdir>

I<(required)>

Directory where Auth will look for its files.  In other words, if C<-sessdir>, 
C<-userfile>, C<-logintmpl>, C<-loginheader> or C<-loginfooter> do not begin 
with a slash (i.e., are not absolute paths), this directory will be prepended 
to them.

=item C<-sessdir>

I<(optional, default = 'sess')>

Directory where Auth will store session files.  These files should be pruned
periodically (i.e., nightly or weekly) since a session file will remain here if 
a user does not log out.

=item C<-userfile>

I<(optional, default = 'user.dat')>

File containing definitions of users, including login information and any extra 
parameters.  This file will be created, edited and read by Auth.pm and its 
command-line administration tool.

=item C<-logintmpl>

I<(optional, excludes C<-loginheader> and C<-loginfooter> if present)>

Template file for use with HTML::Template.  This file must contain a form for 
the user to fill out, and it is recommended that the form not contain any 
elements with names beginning with 'auth_', since these are reserved for 
CGI::Auth fields.  

The template should include the following HTML::Template items.  These are 
case-insensitive.  See the HTML::Template documentation for more information.

B<Template Variables>

=over 4

=item C<Message>

A message to the user, such as "Login failed", "Session expired", etc...

NOTE: This variable might be left blank when the form is created.  So don't
depend on it having a value.

=item C<Form_Action>

The 'action' property of the form that submits the authentication information.

=item C<Button_Name>

The 'name' property of the submit button on the form.  The tag for the button 
should look something like this:

    <input type=submit name="<TMPL_VAR Name=Button_Name>" value="Submit">

The 'value' property of the submit button can be anything.

=back

B<Template Loops>

=over 4

=item C<Auth_Fields>

Provides variables for each required Auth field.  These are the fields which 
will be filled in by the user when logging in.  The following variables are 
provided:

=over 4

=item C<Display_Name>

The display name of the field, e.g., "User Name" or "Password".

=item C<Input_Name>

The 'name' property of the text input for the field.

=item C<Input_Type>

The type, 'text' or 'password', of the input, depending on whether this
field is hidden or not.

=back

=back

=item C<-loginheader>

I<(optional, default = 'login.head' or a simple default header)>

Header for login screen.

NOTE: C<-loginheader> and C<-loginfooter> are ignored if C<-logintmpl> is 
provided.

=item C<-loginfooter>

I<(optional, default = 'login.foot' or a simple default footer)>

Footer for login screen.

NOTE: C<-loginheader> and C<-loginfooter> are ignored if C<-logintmpl> is 
provided.

=item C<-formaction>

I<(optional if C<-admin> given)>

URL of calling script.  This is used by the login screen as the form's "action"
property.

=item C<-authfields>

I<(required)>

Array of hashes defining fields in user database.  This requires at least one 
field, which must be 'required' and not 'hidden'.  Any other fields can be used
to authenticate the user or to contain information about the user such as 
groups, access levels, etc.  Once a user has logged on, all of his fields are
available through the C<data> method.  However, any fields that are marked 
'hidden' will be crypted and not readable by the script.

Each field in the C<-authfields> anonymous array is a hash containing 4 keys: 

    'id'        ID of the field.  This must be unique across all fields.
    'display'   Display string which is presented to the user.
    'hidden'    Flag (0 or 1) that determines whether this field is hidden
                on the login screen and encrypted in the user file.
    'required'  Flag (0 or 1) indicating whether this field must be given
                for authentication.

Here is an example of a simple username/password scheme, with one extra data 
parameter:

    -authfields		=> [
        {id => 'user', display => 'User Name', hidden => 0, required => 1},
        {id => 'pw', display => 'Password', hidden => 1, required => 1},
        {id => 'group', display => 'Group', hidden => 0, required => 0},
    ],

=item C<-timeout>

I<(optional, default = 60 * 15, 15 minutes)>

The timeout value in seconds after which an unused session file will expire.

=back

=head1 METHODS

=over 4

=item C<check>

Ensures authentication.  If the session file is not present or has expired, a 
login form is presented to the user.  A call to this method should occur in 
every script that must be secured.

=item C<data>

Returns a given data field.  The field's ID is passed as the parameter, and the
data is returned.  The special field 'sess_file' returns the name of the
current session file in the C<-sessdir> directory.

=item C<endsession>

Deletes a user's session file so that he must log in again to gain access.

=item C<urlfield>

Returns the session file parameter as a field suitable for tacking onto the end 
of an URL (such as in a link), e.g.: 

    'auth_sessfile=DBEEL87CXV7H'.

=item C<formfield>

Returns the session file parameter as a hidden input field suitable for 
inserting in a E<lt>FORME<gt>, e.g.: 

    '<input type=hidden name="auth_sessfile" value="DBEEL87CXV7H">'

=back

=head1 NOTE ON SECURITY

Any hidden fields such as passwords are sent over the network in clear text, 
so anyone with low-level access to the network (such as an ISP owner or a 
lucky/skilled hacker) could read the passwords and gain access to your 
application.  Auth.pm has no control over this since it is currently a 
server-side-only solution.

If your application must be fully secured, an encryption layer such as HTTPS 
should be used to encrypt the session so that passwords cannot be snooped by 
unauthorized individuals.

=head1 SEE ALSO

C<CGI.pm>

=head1 BUGS

Auth.pm doesn't use cookies, so it is left up to the script author to ensure
that auth data (i.e., the session file) is passed around consistently through 
all links and entry forms.

=head1 AUTHOR

Chad Wallace, cmdrwalrus@canada.com

If you have any suggestions, comments or bug reports, please send them to me.  
I will be happy to hear them.

=head1 COPYRIGHT

Copyright (c) 2001, 2002 Chad Wallace.
All rights reserved.

This module may be distributed and/or modified under the same terms as Perl
itself.

=cut

use Carp;

use strict;

# Variables defined by configuration file.
use vars qw/$VERSION/;

$VERSION = '2.4.1';

# Constructor
sub new 
{
	my $proto = shift;
    my $class = ref($proto) || $proto;
	my $self = {};
	bless $self, $class;

	$self->init(@_) or return undef;

	return $self;
}

# Called by new--all parameters to new are passed off to init for processing.
sub init
{
	my ($self, $param) = (shift, shift);

	return 0 unless (UNIVERSAL::isa($param, 'HASH'));

	# Parameters in an anonymous hash.
	# All config options are passed here... no config file!
	$self->{cgi} = $param->{-cgi};
	$self->{admin} = $param->{-admin};

	$self->{authdir} = $param->{-authdir};
	$self->{sessdir} = $param->{-sessdir};
	for ($self->{authdir}, $self->{sessdir})
	{
		s|/+$|| if ($_);	# Delete trailing slashes.
	}

	$self->{userfile} = $param->{-userfile};
	unless ($self->{logintmpl} = $param->{-logintmpl})			# Either an HTML::Template template, 
	{
		$self->{loginheader} = $param->{-loginheader};			# or a header and footer.
		$self->{loginfooter} = $param->{-loginfooter};
	}
	$self->{formaction} = $param->{-formaction};
	$self->{authfields} = $param->{-authfields};
	$self->{timeout} = $param->{-timeout};

	if ($self->{admin})
	{
		&DenyCGI;
	}
	else
	{
		require CGI;
		$self->{cgi} = UNIVERSAL::isa($self->{cgi}, 'CGI') ? $self->{cgi} : new CGI;
	}

	unless ($self->{authdir} && ($self->{admin} || $self->{formaction}) && $self->{authfields})
	{
		&carp("Auth::init - Missing required configuration data");
		return 0;
	}

	# Set defaults for optional config entries if not given:
	unless ($self->{logintmpl})
	{
		$self->{loginheader}	= 'login.head'	unless ($self->{loginheader});
		$self->{loginfooter}	= 'login.foot'	unless ($self->{loginfooter});
	}
	$self->{sessdir}		= 'sess'		unless ($self->{sessdir});
	$self->{userfile}		= 'user.dat'	unless ($self->{userfile});
	$self->{timeout}		= 60 * 15		unless ($self->{timeout});

	for (@{$self}{qw/sessdir userfile logintmpl loginheader loginfooter/})
	{
		if ($_ and not m{^/})
		{
			$_ = $self->{authdir} . '/' . $_;
		}
	}

	unless (-f $self->{userfile})
	{
		&carp("Auth::init - User data file doesn't exist");
		return 0;
	}

	for (@{$self->{authfields}})
	{
		if ($_->{id} eq 'sess_file')
		{
			&carp("Auth::init - id 'sess_file' is reserved");
			return 0;
		}
	}

	unless ($self->{authfields}->[0]->{required} and not $self->{authfields}->[0]->{hidden})
	{
		&carp("Auth::init - First auth field must be required and not hidden--rethink your auth configuration");
		return 0;
	}

	# Create authdata hash.
	$self->{authdata} = {};

	return 1;
}

sub check
{
	my ($self) = @_;

	my $session_file = $self->{cgi}->param('auth_sessfile');
	if ($session_file)
	{
		# Untaint.
		$session_file =~ s/[^0-9A-Za-z\._]+//g;
		$session_file =~ m/([0-9A-Za-z\._]+)/;
		$self->{sess_file} = $session_file = $1;

		my ($field0) = $self->OpenSessionFile;
		if ($field0)
		{
			return $self->setdata($self->GetUserData($field0));
		}
		elsif (defined $field0)
		{
			$self->PrintLoginForm("Your session has expired.  Please log in again.");
			exit(0);
		}
		else
		{
			$self->PrintLoginForm("Could not open session file.  Please log in again.");
			&carp("Auth::check - Could not open session file");
			exit(0);
		}
	}
	elsif (defined $self->{cgi}->param('auth_submit'))
	{
		my $field0 = $self->{cgi}->param('auth_' . $self->{authfields}->[0]->{id});
		my @userdata = $self->GetUserData($field0);
		# Make sure GetUserData found the user.
		if (not @userdata)
		{
			$self->PrintLoginForm("Authentication failed!  Check login information and try again.");
			exit(0);
		}

		my $failed = 0;
		# Verify required fields in form data with those in @userdata.
		FIELD: for my $idx (1 .. @{$self->{authfields}} - 1)
		{
			if ($self->{authfields}->[$idx]->{required})
			{
				my $formvalue = $self->{cgi}->param('auth_' . $self->{authfields}->[$idx]->{id});
				if ($self->{authfields}->[$idx]->{hidden})
				{
					# Check against crypted userdata.
					if (DoubleCrypt($formvalue, $userdata[$idx]) ne $userdata[$idx])
					{
						++$failed;
						last FIELD;
					}
				}
				else
				{
					# Check against uncrypted userdata.
					if ($userdata[$idx] ne $formvalue)
					{
						++$failed;
						last FIELD;
					}
				}
			}
		}

		if ($failed)
		{
			$self->PrintLoginForm("Authentication failed!  Check login information and try again.");
			exit(0);
		}
		else
		{
			if ($self->{sess_file} = $self->CreateSessionFile($field0))
			{
				return $self->setdata(@userdata);
			}
			else
			{
				$self->PrintLoginForm("A session file could not be created.  You may not be able to log in at this time.");
				&carp("Auth::check - Could not create session file");
				exit(0);
			}
		}
	}
	else
	{
		$self->PrintLoginForm;
		exit(0);
	}
}

# Returns 1 if session file deleted successfully, 
# 0 if an error occurred, or
# -1 if the session file did not exist.
sub endsession
{
	my $self = shift;

	if (-f $self->{sessdir} . "/" . $self->{sess_file})
	{
		return unlink $self->{sessdir} . "/" . $self->{sess_file};
	}
	else
	{
		return -1;
	}
}

sub setdata
{
	my $self = shift;
	my @data = @_;

	return 0 if (@data != @{$self->{authfields}});

	for (my $idx = 0; $idx < @data; ++$idx)
	{
		next if ($self->{authfields}->[$idx]->{hidden});

		# Store non-hidden data in authdata for program to access.
		$self->{authdata}->{$self->{authfields}->[$idx]->{id}} = $data[$idx];
	}

	return 1;
}

sub data
{
	my $self = shift;
	my $key = shift;

	if ($key eq 'sess_file')
	{
		return $self->{sess_file};
	}

	return $self->{authdata}->{$key};
}

sub formfield
{
	my $self = shift;
	
	my $name = 'auth_sessfile';
	my $value = $self->data('sess_file');

	return qq(<input type=hidden name="$name" value="$value">);
}

sub urlfield
{
	my $self = shift;

	my $name = 'auth_sessfile';
	my $value = $self->data('sess_file');

	return qq($name=$value);
}

#--- 'command-line' member functions - for user maintenance.
# These functions cannot be run as a CGI...  
# Use them only in command-line programs as an administrator.

# adduser
#
# The parameters are data values for the @authfields.  
# For example:
#	$auth->adduser('KAM', 'smokey');  # Branchname, Password
sub adduser
{
	my $self = shift;

	&DenyCGI;

	my $salt = join '', ('.', '_', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];

	my @userdata = @_;
	&croak("Bad user data") if (@userdata != @{$self->{authfields}});

	# Append user to user file.
	open USER, ">> " . $self->{userfile} 
		or return 0;
	for (my $idx = 0; $idx < @userdata; ++$idx)
	{
		if ($self->{authfields}->[$idx]->{hidden})
		{
			if (length $userdata[$idx] > 16)
			{
				&croak("Hidden field '" . $self->{authfields}->[$idx]->{display} . "' cannot have length greater than 16 characters");
			}
			# Store encrypted.
			$userdata[$idx] = DoubleCrypt($userdata[$idx], $salt);
		}
	}
	print USER join ('|', @userdata), "\n";
	close USER;
}

sub listusers
{
	my ($self) = @_;

	&DenyCGI;

	open USER, "< " . $self->{userfile} or return;
	while (<USER>)
	{
		my ($br) = split /\|/, $_, 2;
		print "$br\n";
	}
	close USER;
}

sub viewuser
{
	my ($self, $field0) = @_;

	&DenyCGI;

	my @userdata = $self->GetUserData($field0);

	if (@userdata == 0)
	{
		print "$field0 does not exist.\n";
		return 0;
	}
	&croak("Bad user data for $field0") if (@userdata != @{$self->{authfields}});

	for (my $idx = 0; $idx < @userdata; ++$idx)
	{
		my $msg = $self->{authfields}->[$idx]->{display};
		$msg .= " (required)" if ($self->{authfields}->[$idx]->{required});
		$msg .= " (hidden)" if ($self->{authfields}->[$idx]->{hidden});
		$msg .= ": " . $userdata[$idx] . "\n";

		print $msg;
	}
}

sub deluser
{
	my ($self, $field0) = @_;

	&DenyCGI;

	$self->viewuser($field0);

	print "\nDelete this user? ";
	my $resp = <STDIN>;

	# If the response begins with a 'y' (or 'Y'), ie. 'yes' or 'y' or 'you better not!'...
	if ($resp =~ /^y/i)
	{
		open USER, "< " . $self->{userfile} or &croak("Unable to read userfile: $!");
		my @userfile = <USER>;
		close USER;

		open USER, "> " . $self->{userfile} or &croak("Unable to write userfile: $!");
		for (@userfile)
		{
			if (!/^$field0\b/i)
			{
				print USER $_;
			}
		}
		close USER;
		print "\nUser deleted.\n";
	}
	else
	{
		print "\nUser not deleted.\n";
	}
}

sub prune
{
	my $self = shift;

	&DenyCGI;

	my $pruned = 0;

	opendir SESSDIR, $self->{sessdir};
	while (my $file = readdir(SESSDIR))
	{
		$file = $self->{sessdir} . '/' . $file;
		next unless (-f $file);

		my $mtime = (stat _)[9];
		my $now = time;
		my $age = $now - $mtime;

		$pruned += unlink $file if ($age > $self->{timeout});
	}
	closedir SESSDIR;

	return $pruned;
}

#--- 'private' member functions

sub GetUserData
{
	my ($self, $field0) = @_;

	$field0 or return;
	open (USER, "< " . $self->{userfile}) or return;

	my @userdata;
	while (<USER>)
	{
		next if (!/^$field0\|/i);

		# Field 0 found--get user data.
		chop;
		@userdata = split /\|/;
		last;
	}
	close USER;
	return if (lc $userdata[0] ne lc $field0);

	return @userdata;
}

sub PrintLoginForm
{
	my ($self, $msg) = @_;

	print $self->{cgi}->header;

	if ($self->{logintmpl})
	{
		$self->PLF_template($msg);
	}
	else
	{
		$self->PLF_headerfooter($msg);
	}
}

sub PLF_template
{
	my ($self, $msg) = @_;

	require HTML::Template;

	my $template = new HTML::Template(filename => $self->{logintmpl});

	# Create parameters for Auth_Fields <TMPL_LOOP>.
	my @fields = ();
	foreach my $authfield (@{$self->{authfields}})
	{
		if ($authfield->{required})
		{
			push @fields, {
				Display_Name => $authfield->{display}, 
				Input_Name => 'auth_' . $authfield->{id}, 
				Input_Type => $authfield->{hidden} ? 'password' : 'text',
			};
		}
	}

	$template->param(
		Message => $msg,
		Auth_Fields => \@fields,
		Button_Name => 'auth_submit',
		Form_Action => $self->{formaction},
		Form_Fields => $self->FormFields,
	);
	print $template->output();
}

sub PLF_headerfooter
{
	my ($self, $msg) = @_;

	if (open HEADER, "< " . $self->{loginheader})
	{
		my @header = <HEADER>;
		close HEADER;
		print @header;
	}
	else
	{
		print <<DEFAULT;
<html>
<head>
<title>Login</title>
</head>
<body>
<p>Please enter your login information:</p>
DEFAULT
	}

	if ($msg)
	{
		print qq(<p style="color: red; font-weight: bold;">$msg</p>\n);
	}

	my $formaction = $self->{formaction};
	print <<START;
<form method=post action="$formaction">
<table border=0>
START

	print $self->FormFields;

	# Print form for filling in auth fields.
	foreach my $authfield (@{$self->{authfields}})
	{
		if ($authfield->{required})
		{
			if ($authfield->{hidden})
			{
				print "<tr><td align=left><p><b>", $authfield->{display}, ":</b></p></td>", 
					"<td align=left><p><input type=password name=auth_", $authfield->{id}, "></p></td>\n";
			}
			else
			{
				print "<tr><td align=left><p><b>", $authfield->{display}, ":</b></p></td>", 
					"<td align=left><p><input type=text name=auth_", $authfield->{id}, "></p></td>\n";
			}
		}
	}

	print <<END;
</table>
<p><input type=submit name="auth_submit" value="Login"></p>
</form>
END

	if (open FOOTER, "< " . $self->{loginfooter})
	{
		my @footer = <FOOTER>;
		close FOOTER;
		print @footer;
	}
	else
	{
		print "</body></html>\n";
	}
}

sub FormFields
{
	my ($self) = shift;

	my $formfields = '';

	for my $name ($self->{cgi}->param)
	{
		next if ($name =~ /^auth_/);
		my @values = $self->{cgi}->param($name);

		if (@values < 2)	# i.e., 0 or 1 values.
		{
			my $val = $values[0] || '';
			$formfields .= qq(<input type=hidden name="$name" value="$val">\n);
		}
		else
		{
			$formfields .= join ("\n",
				qq(<select multiple name="$name" style="display:none">), 
				(map {qq(<option selected value="$_" style="display:none">$_</option>)} @values), 
				qq(</select>), 
				''		# For a \n at the end.
			);
		}
	}

	return $formfields;
}

sub CreateSessionFile
{
	my ($self, $field0) = @_;

	my @chars = (0..9, 'A'..'Z');
	my $sessfilename;

	my $remoteaddr = $ENV{REMOTE_ADDR};

	do
	{
		$sessfilename = join '', map {$chars[rand 36]} (1..12);
	} while (-e $self->{sessdir} . "/$sessfilename");

	open SESS, "> " . $self->{sessdir} . "/$sessfilename" 
		or return;
	print SESS $field0, "\n";
	print SESS $remoteaddr, "\n" if ( $remoteaddr );
	close SESS;
	
	return $sessfilename;
}

# Returns:	Field 0 value from session file if successful, 
#			0 if session has expired, or
#			undef if session file doesn't exist or can't be opened.
sub OpenSessionFile
{
	my $self = shift;

	my $sessfile = $self->{sessdir} . "/" . $self->{sess_file};
	if (-f $sessfile)
	{
		my $mtime = (stat _)[9];
		my $now = time;
		my $age = $now - $mtime;		# How old is the session file?

		# Check age against timeout value.
		if ($age > $self->{timeout})
		{
			# Too old!
			unlink $sessfile;
			return 0;
		}

		# Attempt to open file.
		if (open (SESS, "< $sessfile"))
		{
			# Read information from file.
			my $field0 = <SESS>;
			my $file_ra = <SESS>;
			close SESS;
			chomp $field0;
			chomp $file_ra;

			# Verify remote IP address.
			if ( $file_ra and $file_ra ne $ENV{REMOTE_ADDR} )
			{
				# IP address doesn't match.
				# Return error: unable to access session file.
				return undef;
			}

			# Update modification time for timeout.
			utime $now, $now, $sessfile;

			# Return Field 0 (ie, user name).
			return $field0;
		}

		# File couldn't be opened.
		&carp("Couldn't open session file $sessfile because '$!'");
	}

	# Non-existent or inaccessible session file.
	return undef;
}

#--- Helper functions (not members)

# Exits if run as CGI.
sub DenyCGI
{
	if ($ENV{REQUEST_METHOD} || $ENV{REMOTE_ADDR})
	{
		print "Content-type: text/html\n\n<html><title>SORRY</title><body><h1>This cannot be run from the web.</h1><h2>GOOD-BYE!</h2></body></html>\n";
		exit;
	}
}

sub DoubleCrypt
{
	my ($str, $salt) = @_;

	# Eliminates warnings about substr beyond end of string.
	if (length($str) > 8)
	{
		return crypt(substr($str, 0, 8), $salt) . crypt(substr($str, 8, 8), $salt);
	}
	else
	{
		return crypt($str, $salt) . crypt('', $salt);
	}
}

# Return true when 'require'd.
1;
