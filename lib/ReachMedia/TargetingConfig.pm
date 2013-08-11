package ReachMedia::TargetingConfig;

use strict;
use URI;
use URI::QueryParam;
use HTTP::Status qw(:constants status_message);
use JSON::XS;
use Data::Dumper;
use Switch;
use DBI;
use Bit::Vector;
use ReachMedia::DBRedis;
use ReachMedia::ModuleRuntime;

our @ISA = ("ReachMedia::ModuleRuntime");
our @INTERFACE = qw(edit insert update delete select status);

@PARENT::ISA = @ISA;

sub new
{
	my $class = shift;
	my (%params) = @_;
	my $self = $class->PARENT::new(name=>'targeting-config', desc=>'Targeting Configurator', debug=> $params{debug} || 0);

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

	# Define interface functions
	foreach my $i (@INTERFACE) {
        $self->{function_table}->{$i} = sub { $self->$i(@_);};
	}

    return $self;
}

# Edit command
sub edit
{
    my $self = shift;
    my $params = shift;
    $self->query($params);
    return $self->http_adapter();
}

# Insert command
sub insert
{
    my $self = shift;
    my $params = shift;
    my $dbh = $self->{_db};
    my $status = 0;
    my $types = {};
    my $sql = "SELECT value FROM conf.status ".
        "INNER JOIN obj.app USING(appid) ".
        "WHERE appid = ? AND deleted != true";
    my $sth = $dbh->prepare($sql);
    $sth->execute($params->{appid});
    if(my $status = $sth->fetchrow_hashref()) {
        if($status->{value} > 0) { return 0x01; }
    }
    else { return 0x7F; }
    my $rv = $sth->finish();

    $sql = "SELECT id, mtype FROM dict.type WHERE deleted != true";
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $type = $sth->fetchrow_hashref()) {
        $types->{$type->{mtype}} = $type->{id};
    }
    $rv = $sth->finish();

    $sql = 'INSERT INTO tmp.ado '.
        '(appid, actionid, seqno, uuid, flink, ilink, tid, name, attr) '.
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?::hstore)';
    $dbh->begin_work();
    foreach my $uuid (keys %{$params->{objects}}) {
        my $object = $params->{objects}->{$uuid};
        my @attr = ();
        if(exists($object->{attr}) && (ref $object->{attr} eq 'HASH')) {
            foreach my $t (keys %{$object->{attr}}) {
                push(@attr, sprintf('%s=>%s', $t, join(';', @{$object->{attr}->{$t}})));
            }
        }
        $sth = $dbh->prepare($sql);
        $sth->execute(  $params->{appid},
                        $self->{cmd}->{actionid},
                        exists($self->{cmd}->{seqno})?$self->{cmd}->{seqno}:0,
                        $uuid,
                        $object->{link},
                        $object->{img},
                        exists($object->{mtype})?$types->{$object->{mtype}}:0,
                        exists($object->{name})?$object->{name}:'',
                        join(',', @attr));
        if ( $sth->err ) {
            printf("DB ERROR #%s (%s): '%s'\n", $sth->err, $sth->state, $sth->errstr);
            $status = 0xFF;
            $status = 0x03 if $sth->state eq '23505';   # DUPLICATED UUID
            $status = 0x7F if $sth->state eq '23503';   # WRONG APPID
            return $status;
        }
        $rv = $sth->finish();
    }
    if($status) {$dbh->rollback();}
    else {$dbh->commit();}

    $sql = 'INSERT INTO obj.ado (appid, uuid, flink, ilink, tid, name, attr) '.
        'SELECT appid, uuid, flink, ilink, tid, name, attr FROM tmp.ado WHERE actionid = ?';
    $sth = $dbh->prepare($sql);
    $sth->execute($self->{cmd}->{actionid});
    if ( $sth->err ) {
        printf("DB ERROR #%s (%s): '%s'\n", $sth->err, $sth->state, $sth->errstr);
        $status = 0xFF;
        $status = 0x03 if $sth->state eq '23505';   # DUPLICATED UUID
        $status = 0x7F if $sth->state eq '23503';   # WRONG APPID
    }
    $rv = $sth->finish();

    $sql = 'DELETE FROM tmp.ado WHERE actionid = ?';
    $sth = $dbh->prepare($sql);
    $sth->execute($self->{cmd}->{actionid});
    if ( $sth->err ) {
        printf("DB ERROR #%s (%s): '%s'\n", $sth->err, $sth->state, $sth->errstr);
        $status = 0xFF;
    }
    $rv = $sth->finish();

    return $status;
}

# Update command
sub update
{
    my $self = shift;
    my $params = shift;

    return {};
}

# Delete command
sub delete
{
    my $self = shift;
    my $params = shift;

    return {};
}

# Select command
sub select
{
    my $self = shift;
    my $params = shift;
    my $response = [];
    my $sql = "SELECT uuid FROM obj.ado ".
        "WHERE appid = ? AND deleted != true";
    my $sth = $self->{_db}->prepare($sql);
    $sth->execute($params->{appid});
    while(my $ado = $sth->fetchrow_hashref()) {
        push(@{$response}, $ado->{uuid});
    }
    my $rv = $sth->finish();
    return $response;
}

# Status command
sub status
{
    my $self = shift;
    my $params = shift;
    my $status = 0;
    my $sql = "SELECT value FROM conf.status ".
        "INNER JOIN obj.app USING(appid) ".
        "WHERE appid = ? AND deleted != true";
    my $sth = $self->{_db}->prepare($sql);
    $sth->execute($params->{appid});
    my $conf = $sth->fetchrow_hashref();
    if ( $sth->err ) { $status = 0xFF; }
    elsif(scalar(keys %{$conf})==0) { $status = 0x7F; }
    else {
        $status = $conf->{value};
    }
    my $rv = $sth->finish();
    return $status;
}

# Function for loading configuration into Redis
sub load
{
    my $self = shift;
    my $params = shift;
    my $response = '';
    my $dbh = $self->{_db};

    my $redis = ReachMedia::DBRedis->new()->connect('localhost', '6379');

    my $sql = "UPDATE conf.status SET value = 3 ".
        "WHERE value = 2 RETURNING appid, cid";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my $t = 0;
    while(my $conf = $sth->fetchrow_hashref()) {
        my @ados;
        my %values;
        my %tags;
        my $appid = $conf->{appid};
        my $cid = $conf->{cid}?0:1;
        $response .= sprintf("appid: %s .... ", $appid);

        $sql = "SELECT tid, priority, weight, uuid FROM conf.current c ".
            "WHERE appid = ? AND cid = ? ".
            "ORDER BY priority DESC, weight DESC, tid ASC";
        my $stha = $dbh->prepare($sql);
        $stha->execute($appid, $cid);
        my $mlength = 0;
        while(my $a = $stha->fetchrow_hashref()) {
            push(@ados, [$a->{tid}, sprintf('i:%d,p:%d,w:%d,u:%s', $mlength++, $a->{priority}, $a->{weight}, $a->{uuid})]);
        }
        if ( $stha->err ) { $response .= sprintf("DB ERROR #%s: '%s'\n", $stha->err, $stha->errstr); $response .= $sql."\n";}

        $sql = "SELECT tid, tag, unnest(values) AS value ".
            "FROM (SELECT tid, (each(attr)).key as tag, regexp_split_to_array((each(attr)).value, ';') as values ".
            "FROM conf.current WHERE appid = ? AND cid = ?) c ORDER BY 1,2,3 ASC";
        $stha = $dbh->prepare($sql);
        $stha->execute($appid, $cid);
        if ( $stha->err ) { $response .= sprintf("DB ERROR #%s: '%s'\n", $stha->err, $stha->errstr); $response .= $sql."\n";}
        while(my $v = $stha->fetchrow_hashref()) {
            if($v->{value} ne '') {
                $values{$v->{tag}}{$v->{value}}{$v->{tid}} = 1;
                $tags{$v->{tid}}{$v->{tag}} = 1;
            }
        }

        $redis->multi();
        # Clean up
        my $prefix = "app:$appid:c:$cid";
        my $tstamp = time();
        $redis->del($prefix.':index', $prefix.':tids', $prefix.':bits');

        # Setting index & object parameters
        for(my $i=0; $i<$mlength; $i++) {
            $redis->rpush($prefix.':index', $ados[$i][0]);
            $redis->hset($prefix.':tids', $ados[$i][0], $ados[$i][1]);
        }

        # Setting bit-masks
        foreach my $t (keys %values) {
            foreach my $v (keys %{$values{$t}}) {
                my $mask = Bit::Vector->new($mlength);
                # Fill in bit-mask for value (little-endian)
                for(my $i=0; $i<$mlength; $i++) {
                    $mask->Bit_On($i) if( exists( $values{$t}{$v}{$ados[$i][0]} ) );
                }
                $redis->hset($prefix.':bits', "$t:$v", $mask->to_Hex());
            }
        }

        # Fill in bit-mask for ALL (little-endian)
        $sql = "SELECT tag FROM dict.attr WHERE deleted != true";
        $stha = $dbh->prepare($sql);
        $stha->execute();
        if ( $stha->err ) { $response .= sprintf("DB ERROR #%s: '%s'\n", $stha->err, $stha->errstr); $response .= $sql."\n";}
        while(my $v = $stha->fetchrow_hashref()) {
            my $mask = Bit::Vector->new($mlength);
            for(my $i=0; $i<$mlength; $i++) {
                $mask->Bit_On($i) if( !exists( $tags{$ados[$i][0]}{$v->{tag}} ) );
            }
            $redis->hset($prefix.':bits', $v->{tag}.":ALL", $mask->to_Hex());
        }

        # Setting config state
        $redis->set("app:$appid:c", "$cid:$mlength:$tstamp");
        $redis->exec();

        $sql = "UPDATE conf.status SET value = 0, cid = ? ".
            "WHERE appid = ?";
        $stha = $dbh->prepare($sql);
        $stha->execute($cid, $appid);

        $t++;
        $response .= "Done.\n";
    }
    if ( $sth->err ) { $response .= sprintf("DB ERROR #%s: '%s'\n", $sth->err, $sth->errstr); $response .= $sql."\n";}
    elsif($t==0) { $response = "No tasks.\n"; }
    my $rv = $sth->finish();
    return $response;
}

# prepare HTTP-response if serve a direct CGI-call
sub http
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

# prepare response for call from http-adapter
sub http_adapter
{
    my $self = shift;
    my @response = ($self->{_status}, []);
    foreach my $h (@{$self->{_header}}) {
        push($response[1], $h->[0], $h->[1]);
    }
    push(@response, $self->{_body});
    return \@response;
}

# Process CGI-query
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

    if(!exists($self->{_query}->{store})) {$self->{_query}->{store} = '';}
	switch($self->{_query}->{store})
	{
		case 'obj.app' {$self->query_app();}
		case 'obj.ado' {$self->query_ado();}
		case 'obj.group' {$self->query_group();}
		case 'obj.group.attr' {$self->query_groupattr();}
		case 'obj.group.ado' {$self->query_groupado();}
		case 'dict.attr' {$self->query_attr();}
		case 'dict.priority' {$self->query_priority();}
		case 'dict.type' {$self->query_type();}
		case 'conf.status' {$self->query_conf();}
		else {$self->{_status} = HTTP_BAD_REQUEST; push(@{$self->{_body}}, '{success:false, err_msg:"Wrong store name"}');}
	}

	use bytes;
	push(@{$self->{_header}}, ['Content-Length', length($self->{_body}->[0])]);
	return $self;
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

sub query_conf
{
    my $self = shift;
    my %odata;
    my $dbh = $self->{_db};

	switch($self->{_action}) {
		case 'read' {
            my $sql = "SELECT appid AS id, value, cid, date_trunc('second', utime::timestamp) as utime FROM conf.status ".
                "INNER JOIN obj.app USING(appid) ".
                "WHERE appid = ? AND deleted != true";
            my $sth = $dbh->prepare($sql);
            $sth->execute($self->{_query}->{appid});
            my $conf = $sth->fetchrow_hashref();
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            elsif(scalar(keys %{$conf})==0) { $odata{success} = JSON::XS::false; $odata{err_msg} = 'App is not exist'; }
            else {
                push @{$odata{results}}, $conf;
                $odata{success} = JSON::XS::true;
            }
            my $rv = $sth->finish();
        }
        case 'update' {
            my $sql = "UPDATE conf.status SET value=1 ".
                "WHERE value = 0 AND appid = ? AND (SELECT deleted FROM obj.app WHERE appid = ?) != true ".
                "RETURNING appid AS id, value, cid, date_trunc('second', utime::timestamp) as utime";
            my $sth = $dbh->prepare($sql);
            $sth->execute($self->{_query}->{appid}, $self->{_query}->{appid});
            my $conf = $sth->fetchrow_hashref();
            if ( $sth->err ) { $odata{success} = JSON::XS::false; $odata{err_code} = $sth->err; $odata{err_msg} = $sth->errstr; }
            elsif(scalar(keys %{$conf})==0) { $odata{success} = JSON::XS::false; $odata{err_msg} = 'App is not exist or configuration is already updated'; }
            else {
                $dbh->begin_work();

                $sql = "DELETE FROM conf.current WHERE appid = ? AND cid = ?";
                my $sthc = $dbh->prepare($sql);
                $sthc->execute($self->{_query}->{appid}, $conf->{cid}?0:1);
                my $rvc = $sthc->finish();
                if ( $sthc->err ) { die($sthc->errstr); }

                $sql = "INSERT INTO conf.current(appid, tid, uuid, attr, weight, priority, cid) ".
                    "SELECT a.appid, a.id||':'||g.id AS tid, a.uuid, g.attr, g.weight, p.value AS priority, ? as cid ".
                    "FROM obj.ado a ".
                    "INNER JOIN obj.ado2group a2g ON a.id=a2g.oid ".
                    "INNER JOIN obj.group g ON g.id=a2g.gid ".
                    "INNER JOIN dict.priority p ON g.priorityid=p.id ".
                    "WHERE a2g.enable=true AND g.enable=true AND g.deleted!=true AND a.deleted!=true AND g.appid=a.appid AND a.appid = ?";
                $sthc = $dbh->prepare($sql);
                $sthc->execute($conf->{cid}?0:1, $self->{_query}->{appid});
                $rvc = $sthc->finish();

                $sql = "UPDATE conf.status SET value=2 ".
                    "WHERE value = 1 AND appid = ?";
                $sthc = $dbh->prepare($sql);
                $sthc->execute($self->{_query}->{appid});
                $rvc = $sthc->finish();

                $dbh->commit();

                push @{$odata{results}}, $conf;
                $odata{success} = JSON::XS::true;
            }
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
        push(@t, sprintf('"%s"=>"%s"', $a->{tag}, join(';', @{$a->{values}})));
    }
    return join(',', @t);
}

1;