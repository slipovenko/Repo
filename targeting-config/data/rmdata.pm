package rmdata;

use strict;
use CGI;
use JSON::XS;
use Data::Dumper;
use Switch;
use DBI;

#$dbh->disconnect();

sub new
{
	my($class) = shift;
	my $self =	{};
	bless $self, $class;
    return $self;
}

sub init
{
	my($self) = @_;
	$self->{_cgi} = CGI->new;

	my $host = "127.0.0.1";
	my $port = "5432";
	my $dbname = "targeting";
	my $username = "rm";
	my $password = "rm";

	$self->{_db} = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port","$username","$password", 
		{PrintError => 0});
	if ($DBI::err != 0) 
	{
		print $DBI::errstr . "\n";
		exit($DBI::err);
	}
}

sub out
{
	my($self) = @_;
	my $out;
	my $header;

	my $obj = $self->{_cgi}->url_param('obj');

	my $dtype = defined($self->{_cgi}->url_param('dtype')) ? $self->{_cgi}->url_param('dtype') : 'json';
	if($dtype eq 'json')
	{
		$header = "Content-type: application/json\n\n";
		my $pdata = $self->{_cgi}->param( 'POSTDATA' );
		if($pdata =~ /^\s*\{.*\}\s*$/)
		{
			$self->{_idata} = decode_json($pdata);
		}
	}
	else
	{
		$header = "Content-type: text/plain\n\n";
		return $header.'Unsupported type: $dtype';
	}

    $self->{_action} = defined($self->{_cgi}->url_param('action')) ? $self->{_cgi}->url_param('action') : 'read';
	switch($obj)
	{
		case 'app' {$out = $self->out_app();}
		case 'ado' {$out = $self->out_ado();}
		case 'group' {$out = $self->out_group();}
		case 'dict.attr' {$out = $self->out_attr();}
		case 'dict.attrvalue' {$out = $self->out_attrvalue();}
		case 'dict.priority' {$out = $self->out_priority();}
		case 'dict.type' {$out = $self->out_type();}
	}
	return $header.$out;
}

sub out_app
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};
	my $idata = \%{$self->{_idata}};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.app(appid,name) VALUES (?, ?)";
				$odata{success} = "true";
			}
		case 'read'
			{
				my $sql = "SELECT id,appid,name FROM obj.app WHERE deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute();
				while(my $app = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $app;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.app SET appid = ?, name = ? WHERE id = ? AND deleted != true";
				my $data = $self->{_cgi}->param( 'POSTDATA');
				if($idata->{id} =~ /\d+/)
				{						
					my $sth = $dbh->prepare($sql);
					$sth->execute($idata->{appid}, $idata->{name}, $idata->{id});
					if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
					else { $odata{success} = "true"; }
					my $rv = $sth->finish();
				}
			}
		case 'delete'
			{
				my $sql = "UPDATE obj.app SET deleted = true WHERE id = ?";
				$odata{success} = "true";
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_ado
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};
	my $idata = \%{$self->{_idata}};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.ado(appid,uuid,flink,ilink,tid,name,attr) VALUES (?, ?, ?, ?, ?, ?, ?)";
				$odata{success} = "true";
			}
		case 'read'
			{
				my $sql = "SELECT id,uuid,flink,ilink,tid,name,attr FROM obj.ado WHERE appid = ? AND deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute($self->{_cgi}->url_param('appid'));
				while(my $ado = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $ado;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.ado SET name = ? WHERE id = ? AND deleted != true";
				if($idata->{id} =~ /\d+/)
				{						
					my $sth = $dbh->prepare($sql);
					$sth->execute($idata->{name}, $idata->{id});
					if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
					else { $odata{success} = "true"; }
					my $rv = $sth->finish();
				}
			}
		case 'delete'
			{
				my $sql = "UPDATE obj.ado SET deleted = true WHERE id = ?";
				$odata{success} = "true";
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_group
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};
	my $idata = \%{$self->{_idata}};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.group(name,attr,weight,priorityid,enable) VALUES (?, ?, ?, ?, ?)";
				$odata{success} = "true";
			}
		case 'read'
			{
				my $sql = "SELECT id,name,attr,weight,priorityid,enable FROM obj.group WHERE appid = ? AND deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute($self->{_cgi}->url_param('appid'));
				while(my $group = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.group SET name = ?, weight = ?, priorityid = ? WHERE id = ? AND deleted != true";
				if($idata->{id} =~ /\d+/)
				{						
					my $sth = $dbh->prepare($sql);
					$sth->execute($idata->{name}, $idata->{weight}, $idata->{priorityid}, $idata->{id});
					if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
					else { $odata{success} = "true"; }
					my $rv = $sth->finish();
				}
			}
		case 'delete'
			{
				my $sql = "UPDATE obj.group SET deleted = true WHERE id = ?";
				$odata{success} = "true";
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_attr
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'read'
			{
				my $sql = "SELECT id, tag, name FROM dict.attr WHERE deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute();
				while(my $group = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_attrvalue
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'read'
			{
				my $sql = "SELECT id, value, name FROM dict.attr_value WHERE aid = ? AND deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute($self->{_cgi}->url_param('attrid'));
				while(my $group = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_priority
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'read'
			{
				my $sql = "SELECT id, value, name FROM dict.priority WHERE deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute();
				while(my $group = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_type
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'read'
			{
				my $sql = "SELECT id, mtype, name FROM dict.type WHERE deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute();
				while(my $group = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = "false"; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = "true"; }
				my $rv = $sth->finish();
			}
	}

	return JSON::XS->new->encode(\%odata);
}

sub format
{
	return '';
}

1;