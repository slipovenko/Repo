package ReachMedia::tgconfig;

use strict;
use URI;
use URI::QueryParam;
use HTTP::Status qw(:constants status_message);
use JSON::XS;
use Data::Dumper;
use Switch;
use DBI;

sub new
{
	my $class = shift;
	my $self =	{};

    my $host = "127.0.0.1";
    my $port = "5432";
    my $dbname = "targeting";
    my $username = "rm";
    my $password = "rm";

    $self->{_db} = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port","$username","$password",
        {PrintError => 0});
    if (! defined $self->{_db})
    {
        $self->{_status} = HTTP_INTERNAL_SERVER_ERROR;
        $self->{_header} = [['Content-Type', 'text/plain; charset=utf-8']];
        $self->{_body} = [sprintf("DB Connection error. Error #%s: %s", $DBI::err, $DBI::errstr)];
        push(@{$self->{_header}},['Content-Length', length($self->{_body}->[0])]);
    }
    $self->{_json} = JSON::XS->new->latin1;

	bless($self, $class);
    return $self;
}

sub query
{
	my $self = shift;
    if(! defined $self->{_db}) { return $self; }
	my $out;
	my $header;

    $self->{_parameters} = shift;
    $self->{_query} = {};
    my $url = URI->new('http://'.$self->{_parameters}->{SERVER_NAME}.$self->{_parameters}->{REQUEST_URI});
    foreach my $p ($url->query_param()) {
        $self->{_query}->{$p} = $url->query_param($p) if (defined $url->query_param($p));
    }
    $self->{_action} = defined($self->{_query}->{action}) ? $self->{_query}->{action} : 'read';

    $self->{_status} = HTTP_OK;
    $self->{_header} = [];
    $self->{_body} = [];

	my $dtype = defined($self->{_query}->{dtype}) ? $self->{_query}->{dtype} : 'json';
	if($dtype eq 'json')
	{
		push(@{$self->{_header}}, ['Content-Type', 'application/json; charset=utf-8']);
		$self->{_idata} = [];
		if($self->{_parameters}->{REQUEST_METHOD} eq 'POST')
		{
            my $pdata = $self->{_parameters}->{INPUT_DATA};
            if($pdata =~ /^\s*((\{.*\})|(\[.*\]))\s*$/)
            {
                my $idata = decode_json($pdata);
                if(ref $idata eq 'HASH') { push( @{$self->{_idata}}, $idata ); }
                elsif(ref $idata eq 'ARRAY') { $self->{_idata} = $idata; }
                else {
                    $self->{_status} = HTTP_BAD_REQUEST;
                    push(@{$self->{_body}}, '{success:false, err_msg:"Wrong format for POST data"}');
                    push(@{$self->{_header}}, ['Content-length', length($self->{_body}->[0])]);
                    return $self;
                }
            }
		}
	}
	else
	{
        $self->{_status} = HTTP_BAD_REQUEST;
        push(@{$self->{_body}}, "Unsupported type: $dtype");
        push(@{$self->{_header}}, ['Content-Type', 'text/plain; charset=utf-8']);
        push(@{$self->{_header}}, ['Content-Length', length($self->{_body}->[0])]);
        return $self;
	}

	switch($self->{_query}->{obj})
	{
		case 'app' {$self->query_app();}
		case 'ado' {$self->query_ado();}
		case 'group' {$self->query_group();}
		case 'group.attr' {$self->query_groupattr();}
		case 'group.ado' {$self->query_groupado();}
		case 'dict.attr' {$self->query_attr();}
		case 'dict.priority' {$self->query_priority();}
		case 'dict.type' {$self->query_type();}
		else {$self->{_status} = HTTP_BAD_REQUEST; push(@{$self->{_body}}, '{success:false, err_msg:"Unsupported object type"}');}
	}

	use bytes;
	push(@{$self->{_header}}, ['Content-Length', length($self->{_body}->[0])]);
	return $self;
}

sub http_response
{
    my $self = shift;
    my $response = sprintf("HTTP/1.1 %d %s\n", $self->{_status}, status_message($self->{_status}));
    foreach my $h (@{$self->{_header}}) {
        $response .= sprintf("%s: %s\n", $h->[0], $h->[1]);
    }
    $response .= "\n";
    $response .= $self->{_body}->[0];
    return $response;
}

sub response
{
    my $self = shift;
    my @response = ($self->{_status}, []);
    foreach my $h (@{$self->{_header}}) {
        push($response[1], $h->[0], $h->[1]);
    }
    push(@response, $self->{_body});
    return \@response;
}

sub query_app
{
	my $self = shift;
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

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_ado
{
	my $self = shift;
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
				$sth->execute($self->{_query}->{appid});
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

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_group
{
	my $self = shift;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action})
	{
		case 'create'
			{
				my $sql = "INSERT INTO obj.group(appid,name,attr,weight,priorityid,enable) VALUES (?, ?, ?::hstore, ?, ?, ?) ".
				    "RETURNING id,appid,name,obj.group_get_attr_as_json(id) AS attr,weight,priorityid,enable";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    $r->{attr} = (ref $r->{attr} eq 'ARRAY')?to_hstore($r->{attr}):'';
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
                        my $group = $sth->fetchrow_hashref();
                        $group->{attr} = decode_json($group->{attr});
                        push @{$odata{results}}, $group;
                    }
                    my $rv = $sth->finish();
                }
                if ( $errcnt>0 ) { $dbh->rollback(); $odata{success} = JSON::XS::false; $odata{errcnt} = $errcnt; }
                else { $dbh->commit(); $odata{success} = JSON::XS::true; }
			}
		case 'read'
			{
				my $sql = "SELECT id,appid,name,obj.group_get_attr_as_json(id) AS attr,weight,priorityid,enable ".
				    "FROM obj.group WHERE appid = ? AND deleted != true ORDER BY 1 ASC";
				my $sth = $dbh->prepare($sql);
				$sth->execute($self->{_query}->{appid});
				while(my $group = $sth->fetchrow_hashref())
				{
				    $group->{attr} = decode_json($group->{attr});
					push @{$odata{results}}, $group;
				}
				if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
				else { $odata{success} = JSON::XS::true; }
				my $rv = $sth->finish();
			}
		case 'update'
			{
				my $sql = "UPDATE obj.group SET name = ?, attr = attr || ?::hstore, weight = ?, priorityid = ?, enable = ? WHERE id = ? AND deleted != true";
				my $errcnt = 0;

				$dbh->begin_work();
				foreach my $r (@idata)
				{
                    $r->{attr} = (ref $r->{attr} eq 'ARRAY')?to_hstore($r->{attr}):'';
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($r->{name}, $r->{attr}, $r->{weight}, $r->{priorityid}, $r->{enable}, $r->{id});
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

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_groupattr
{
	my($self) = @_;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action}) {
		case 'read' {
            my $sql = "SELECT v.id, gid, aid, tag, value FROM ".
                    "(SELECT g.id AS gid, a.id AS aid, a.tag, unnest(g.values) AS value FROM ".
                    "(SELECT id, (each(attr)).key as tag, regexp_split_to_array((each(attr)).value, ';') as values ".
                    "FROM obj.group WHERE id = ?) g ".
                    "INNER JOIN dict.attr a ".
                    "USING(tag)) ga ".
                    "INNER JOIN dict.attr_value v ".
                    "USING(aid,value)";
            my $sth = $dbh->prepare($sql);
            $sth->execute($self->{_query}->{id});
            while(my $groupattr = $sth->fetchrow_hashref()) {
                push @{$odata{results}}, $groupattr;
            }
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            else { $odata{success} = JSON::XS::true; }
            my $rv = $sth->finish();
        }
		else { $odata{success} = JSON::XS::false; }
	}

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_groupado
{
	my $self = shift;
	my %odata;
	my @idata = @{$self->{_idata}};
	my $dbh = $self->{_db};

	switch($self->{_action}) {
		case 'read' {
            my $sql = "SELECT a.id, g.gid, g.enable, a.name, a.tid ".
                    "FROM obj.ado2group g ".
                    "INNER JOIN obj.ado a ".
                    "ON g.oid = a.id ".
                    "WHERE g.gid = ? AND a.deleted = false";
            my $sth = $dbh->prepare($sql);
            $sth->execute($self->{_query}->{gid});
            while(my $groupattr = $sth->fetchrow_hashref()) {
                push @{$odata{results}}, $groupattr;
            }
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            else { $odata{success} = JSON::XS::true; }
            my $rv = $sth->finish();
        }
		else { $odata{success} = JSON::XS::false; }
	}

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_attr
{
	my $self = shift;
	my %odata;
	my $dbh = $self->{_db};
	my $node = defined($self->{_query}->{node}) ? $self->{_query}->{node} : 'root';

	switch($self->{_action}) {
		case 'read' {
            switch($node) {
                case 'root' {
                    my $sql = "SELECT tag AS id, tag, name FROM dict.attr WHERE deleted != true ORDER BY id ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute();
                    while(my $attr = $sth->fetchrow_hashref()) {
                        $attr->{expandable} = JSON::XS::true;
                        push @{$odata{children}}, $attr;
                    }
                    if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    my $rv = $sth->finish();
                }
                case 'geo' {
                    my $sql = "SELECT id, tag, value, name, ".
                            "CAST(value AS integer) / 10000000 AS value1, CAST(value AS integer) / 10000 AS value2, CAST(value AS integer) AS value3, ".
                            "split_part(name, ';', 1) AS name1, split_part(name, ';', 2) AS name2, split_part(name, ';', 3) AS name3 ".
                            "INTO TEMP tmpgeo FROM ".
                            "(SELECT v.id, a.tag, v.value, v.name FROM dict.attr_value v ".
                            "INNER JOIN dict.attr a ON v.aid=a.id ".
                            "WHERE a.tag = ? AND v.deleted != true) g ".
                            "ORDER BY value ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($self->{_query}->{node});
                    my $rv = $sth->finish();

                    $sql = "SELECT tag,10000000*value1 AS value, name1 AS name, COUNT(*) AS cnt ".
                            "FROM tmpgeo GROUP BY 1,2,3 ORDER BY 2";
                    my $sth1 = $dbh->prepare($sql);
                    $sth1->execute();
                    while(my $attrv1 = $sth1->fetchrow_hashref()) {
                        $attrv1->{checked} = JSON::XS::false;
                        if($attrv1->{cnt} == 1) {
                            $sql = "SELECT id FROM tmpgeo WHERE 10000000*value1 = ? AND name1 = ?";
                            my $sth = $dbh->prepare($sql);
                            $sth->execute($attrv1->{value}, $attrv1->{name});
                            ($attrv1->{id}) = $sth->fetchrow_array();
                            my $rv = $sth->finish();
                            $attrv1->{leaf} = JSON::XS::true;
                            push @{$odata{children}}, $attrv1;
                        }
                        else {
                            $attrv1->{id} = $attrv1->{tag}.$attrv1->{value};
                            $attrv1->{expandable} = JSON::XS::true;
                            $sql = "SELECT tag, 10000*value2 AS value, name2 AS name, COUNT(*) AS cnt ".
                                    "FROM tmpgeo WHERE value1 = ? GROUP BY 1,2,3 ORDER BY 2";
                            my $sth2 = $dbh->prepare($sql);
                            $sth2->execute($attrv1->{value}/10000000);
                            while(my $attrv2 = $sth2->fetchrow_hashref()) {
                                $attrv2->{checked} = JSON::XS::false;
                                if($attrv2->{cnt} == 1) {
                                    $sql = "SELECT id FROM tmpgeo WHERE 10000*value2 = ? AND name2 = ?";
                                    my $sth = $dbh->prepare($sql);
                                    $sth->execute($attrv2->{value}, $attrv2->{name});
                                    ($attrv2->{id}) = $sth->fetchrow_array();
                                    my $rv = $sth->finish();
                                    $attrv2->{leaf} = JSON::XS::true;
                                    push @{$attrv1->{children}}, $attrv2;
                                }
                                else {
                                    $attrv2->{id} = $attrv2->{tag}.$attrv2->{value};
                                    $attrv2->{expandable} = JSON::XS::true;
                                    $sql = "SELECT id, tag, value3 AS value, name3 AS name ".
                                            "FROM tmpgeo WHERE value2 = ? ORDER BY 3";
                                    my $sth3 = $dbh->prepare($sql);
                                    $sth3->execute($attrv2->{value}/10000);
                                    while(my $attrv3 = $sth3->fetchrow_hashref()) {
                                        $attrv3->{leaf} = JSON::XS::true;
                                        $attrv3->{checked} = JSON::XS::false;
                                        push @{$attrv2->{children}}, $attrv3;
                                    }
                                    push @{$attrv1->{children}}, $attrv2;
                                }

                            }
                            push @{$odata{children}}, $attrv1;
                            if ( $sth2->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth2->err; $odata{err_msg} = $sth2->errstr; }
                            else { $odata{success} = JSON::XS::true; }
                            $rv = $sth2->finish();
                        }
                    }
                    if ( $sth1->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth1->err; $odata{err_msg} = $sth1->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    $rv = $sth1->finish();
                }
                case 'age' {
                    my $sql = "SELECT id, tag, value, name, ".
                            "CASE WHEN CAST(value AS integer)=0 THEN CAST(value AS integer) ELSE 1+(CAST(value AS integer)-1)/10 END AS tens  ".
                            "INTO TEMP tmpage FROM ".
                            "(SELECT v.id, a.tag, v.value, v.name FROM dict.attr_value v ".
                            "INNER JOIN dict.attr a ON v.aid=a.id ".
                            "WHERE a.tag = ? AND v.deleted != true) g ".
                            "ORDER BY value ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($self->{_query}->{node});
                    my $rv = $sth->finish();

                    $sql = "SELECT tag, tens, COUNT(*) AS cnt ".
                            "FROM tmpage GROUP BY 1,2 ORDER BY 2";
                    my $sth1 = $dbh->prepare($sql);
                    $sth1->execute();
                    while(my $attrv1 = $sth1->fetchrow_hashref()) {
                        $attrv1->{checked} = JSON::XS::false;
                        if($attrv1->{cnt} == 1) {
                            $sql = "SELECT id, tag, name, value FROM tmpage WHERE tens = ?";
                            my $sth = $dbh->prepare($sql);
                            $sth->execute($attrv1->{tens});
                            ($attrv1->{id}, $attrv1->{tag}, $attrv1->{name}, $attrv1->{value}) = $sth->fetchrow_array();
                            my $rv = $sth->finish();
                            $attrv1->{leaf} = JSON::XS::true;
                            push @{$odata{children}}, $attrv1;
                        }
                        else {
                            $attrv1->{id} = $attrv1->{tag}.$attrv1->{tens};
                            $attrv1->{value} = $attrv1->{tens};
                            $attrv1->{expandable} = JSON::XS::true;
                            $sql = "SELECT id, tag, value, name ".
                                    "FROM tmpage WHERE tens = ? ORDER BY CAST(value AS integer)";
                            my $sth2 = $dbh->prepare($sql);
                            $sth2->execute($attrv1->{tens});
                            my $i = 1;
                            while(my $attrv2 = $sth2->fetchrow_hashref()) {
                                $attrv2->{leaf} = JSON::XS::true;
                                $attrv2->{checked} = JSON::XS::false;
                                if($i == 1) {$attrv1->{name}='от '.$attrv2->{name}.'а'}
                                if($i == 10) {$attrv1->{name}.=' до '.$attrv2->{name}}
                                push @{$attrv1->{children}}, $attrv2;
                                $i++;
                            }
                            push @{$odata{children}}, $attrv1;
                            if ( $sth2->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth2->err; $odata{err_msg} = $sth2->errstr; }
                            else { $odata{success} = JSON::XS::true; }
                            $rv = $sth2->finish();
                        }
                    }
                    if ( $sth1->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth1->err; $odata{err_msg} = $sth1->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    $rv = $sth1->finish();
                }
                else {
                    my $sql = "SELECT v.id, a.tag, v.value, v.name FROM dict.attr_value v ".
                            "INNER JOIN dict.attr a ON v.aid=a.id ".
                            "WHERE a.tag = ? AND v.deleted != true ORDER BY v.id ASC";
                    my $sth = $dbh->prepare($sql);
                    $sth->execute($self->{_query}->{node});
                    while(my $attrv = $sth->fetchrow_hashref()) {
                        $attrv->{leaf} = JSON::XS::true;
                        $attrv->{checked} = JSON::XS::false;
                        push @{$odata{children}}, $attrv;
                    }
                    if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
                    else { $odata{success} = JSON::XS::true; }
                    my $rv = $sth->finish();
                }
            }
		}
		else { $odata{success} = JSON::XS::false; }
	}

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_priority
{
	my $self = shift;
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

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub query_type
{
	my $self = shift;
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

	push(@{$self->{_body}}, $self->{_json}->encode(\%odata));
}

sub to_hstore
{
    my $attr = shift;
    my @t = ();
    foreach my $a (@{$attr})
    {
        push(@t, sprintf('%s=>%s', $a->{tag}, join(';', @{$a->{values}})));
    }
    return join(',', @t);
}

1;