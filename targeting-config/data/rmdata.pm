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
		$self->{_idata} = [];
		if($self->{_cgi}->request_method() eq 'POST')
		{
            my $pdata = $self->{_cgi}->param( 'POSTDATA' );
            if($pdata =~ /^\s*((\{.*\})|(\[.*\]))\s*$/)
            {
                my $idata = decode_json($pdata);
                if(ref $idata eq 'HASH') { push( @{$self->{_idata}}, $idata ); }
                elsif(ref $idata eq 'ARRAY') { $self->{_idata} = $idata; }
                else { return $header.'{success:false}';}
            }
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
		case 'group.attr' {$out = $self->out_groupattr();}
		case 'dict.attr' {$out = $self->out_attr();}
		case 'dict.priority' {$out = $self->out_priority();}
		case 'dict.type' {$out = $self->out_type();}
	}
	return $header.$out;
}

sub out_app
{
	my($self) = @_;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.app(appid,name) VALUES (?, ?) RETURNING id,appid,name";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{appid}, $r->{name});
                    if ( $sth->err )
                    {
                        my %rep = ('appid' => $r->{appid}, 'name' => $r->{name}, 'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    else
                    {
                        push @{$odata{results}}, $sth->fetchrow_hashref();
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
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
				if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = JSON::XS::true; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.app SET appid = ?, name = ? WHERE id = ? AND deleted != true";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{appid}, $r->{name}, $r->{id});
                    if ( $sth->err )
                    {
                        my %rep = ('id' => $r->{id}, 'appid' => $r->{appid}, 'name' => $r->{name}, 'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		case 'destroy'
			{
				my $sql = "UPDATE obj.app SET deleted = true WHERE id = ?";
                my $errcnt = 0;

                $dbh->begin_work();
                foreach my $r (@idata)
                {
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{id});
                    if ( $sth->err )
                    {
                        my %rep = ('id' => $r->{id}, 'appid' => $r->{appid}, 'name' => $r->{name}, 'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_ado
{
	my($self) = @_;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.ado(appid,uuid,flink,ilink,tid,name,attr) VALUES (?, ?, ?, ?, ?, ?, ?)";
				$odata{success} = JSON::XS::false;
			}
		case 'read'
			{
				my $sql = "SELECT id,appid,uuid,flink,ilink,tid,name,attr FROM obj.ado WHERE appid = ? AND deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute($self->{_cgi}->url_param('appid'));
				while(my $ado = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $ado;
				}
				if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = JSON::XS::true; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.ado SET name = ?, tid = ? WHERE id = ? AND deleted != true";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{name}, $r->{tid}, $r->{id});
                    if ( $sth->err )
                    {
                        my %rep = ('id' => $r->{id}, 'name' => $r->{name}, 'tid' => $r->{tid}, 'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		case 'destroy'
			{
				my $sql = "UPDATE obj.ado SET deleted = true WHERE id = ?";
				$odata{success} = JSON::XS::false;
			}
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_group
{
	my($self) = @_;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.group(appid,name,attr,weight,priorityid,enable) VALUES (?, ?, ?, ?, ?, ?) ".
				    "RETURNING id,appid,name,attr,weight,priorityid,enable";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{appid}, $r->{name}, $r->{attr}, $r->{weight}, $r->{priorityid}, $r->{enable});
                    if ( $sth->err )
                    {
                        my %rep = ('appid' => $r->{appid}, 'name' => $r->{name}, 'attr' => $r->{attr},
                            'weight' => $r->{weight}, 'priorityid' => $r->{priorityid}, 'enable' => $r->{enable},
                            'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    else
                    {
                        push @{$odata{results}}, $sth->fetchrow_hashref();
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		case 'read'
			{
				my $sql = "SELECT id,appid,name,attr,weight,priorityid,enable FROM obj.group WHERE appid = ? AND deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute($self->{_cgi}->url_param('appid'));
				while(my $group = $sth->fetchrow_hashref())
				{
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = JSON::XS::true; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.group SET name = ?, weight = ?, priorityid = ?, enable = ? WHERE id = ? AND deleted != true";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{name}, $r->{weight}, $r->{priorityid}, $r->{enable}, $r->{id});
                    if ( $sth->err )
                    {
                        my %rep = ('id' => $r->{id}, 'name' => $r->{name}, 'weight' => $r->{weight},
                            'priorityid' => $r->{priorityid}, 'enable' => $r->{enable},
                            'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		case 'destroy'
			{
				my $sql = "UPDATE obj.group SET deleted = true WHERE id = ?";
                my $errcnt = 0;

                $dbh->begin_work();
                foreach my $r (@idata)
                {
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{id});
                    if ( $sth->err )
                    {
                        my %rep = ('id' => $r->{id}, 'err_code' => $sth->err, 'err_msg' => $sth->errstr);
                        push @{$odata{results}}, \%rep;
                        $errcnt++;
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_groupattr
{
	my($self) = @_;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action}) {
		case 'read' {
            my $sql = "SELECT g.id AS id, a.id AS aid, g.values FROM ".
                        "(SELECT id, (each(attr)).key as tag, (each(attr)).value as values ".
                        "FROM obj.group WHERE id = ?) g ".
                        "INNER JOIN dict.attr a ".
                        "USING(tag)";
            my $sth = $dbh->prepare($sql);
            $sth->execute($self->{_cgi}->url_param('id'));
            while(my $groupattr = $sth->fetchrow_hashref()) {
                push @{$odata{results}}, $groupattr;
            }
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            else { $odata{success} = JSON::XS::true; }
            my $rv = $sth->finish();
        }
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_attr
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};
	my $node = defined($self->{_cgi}->url_param('node'))?$self->{_cgi}->url_param('node'):'root';

	switch($self->{_action}) {
		case 'read' {
            switch($node) {
                case 'root' {
                    my $sql = "SELECT tag AS id, tag, name FROM dict.attr WHERE deleted != true ORDER BY id ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute();
                    while(my $attr = $sth->fetchrow_hashref()) {
                        $attr->{expandable} = JSON::XS::true;
                        push @{$odata{results}}, $attr;
                    }
                    if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    my $rv = $sth->finish();
                }
                case 'geo' {
                    my $sql = "SELECT v.id, a.tag, v.value, v.name INTO TEMP tmpgeo FROM dict.attr_value v ".
                            "INNER JOIN dict.attr a ON v.aid=a.id ".
                            "WHERE a.tag = ? AND v.deleted != true ORDER BY v.value ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($self->{_cgi}->url_param('node'));
                    my $rv = $sth->finish();

                    $sql = 'SELECT id, tag, value, name FROM tmpgeo WHERE CAST(value AS integer) < 10000000';
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    while(my $attrv = $sth->fetchrow_hashref()) {
                        $attrv->{leaf} = JSON::XS::true;
                        $attrv->{checked} = JSON::XS::false;
                        push @{$odata{results}}, $attrv;
                    }
                    if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    $rv = $sth->finish();

                    $sql = "SELECT 'geo'||(10000000*(CAST(value AS integer) / 10000000)) AS id, ".
                            "tag, 10000000*(CAST(value AS integer) / 10000000) AS value, ".
                            "split_part(name, ';', 1) AS name FROM tmpgeo WHERE CAST(value AS integer) >= 10000000 ".
                            "GROUP BY 1,2,3,4 ORDER BY 1";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    while(my $attrv = $sth->fetchrow_hashref()) {
                        $attrv->{expandable} = JSON::XS::true;
                        $attrv->{checked} = JSON::XS::false;
                        push @{$odata{results}}, $attrv;
                    }
                    if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    $rv = $sth->finish();
                }
                else {
                    my $sql = "SELECT v.id, a.tag, v.value, v.name FROM dict.attr_value v ".
                            "INNER JOIN dict.attr a ON v.aid=a.id ".
                            "WHERE a.tag = ? AND v.deleted != true ORDER BY v.value ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($self->{_cgi}->url_param('node'));
                    while(my $attrv = $sth->fetchrow_hashref()) {
                        $attrv->{leaf} = JSON::XS::true;
                        $attrv->{checked} = JSON::XS::false;
                        push @{$odata{results}}, $attrv;
                    }
                    if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    my $rv = $sth->finish();
                }
            }
		}
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_priority
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};

	switch($self->{_action}) {
		case 'read' {
            my $sql = "SELECT id, value, name FROM dict.priority WHERE deleted != true ORDER BY 1 ASC";
            my $sth = $dbh->prepare($sql);
            $sth->execute();
            while(my $group = $sth->fetchrow_hashref()) {
                push @{$odata{results}}, $group;
            }
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            else { $odata{success} = JSON::XS::true; }
            my $rv = $sth->finish();
        }
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub out_type
{
	my($self) = @_;
	my %odata;
	my $dbh = $self->{_db};

	switch($self->{_action}) {
		case 'read' {
            my $sql = "SELECT id, mtype, name FROM dict.type WHERE deleted != true ORDER BY 1 ASC";
            my $sth = $dbh->prepare($sql);
            $sth->execute();
            while(my $group = $sth->fetchrow_hashref()) {
                push @{$odata{results}}, $group;
            }
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            else { $odata{success} = JSON::XS::true; }
            my $rv = $sth->finish();
        }
		else { $odata{success} = JSON::XS::false; }
	}

	return JSON::XS->new->encode(\%odata);
}

sub format
{
	return '';
}

1;