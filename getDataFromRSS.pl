#!/usr/bin/perl -w

use strict;
use utf8;
use warnings;
use LWP::Simple;
use XML::LibXML;
use Data::Dumper;
use DBI;


my $db_host = "127.0.0.1";
my $db_port = "5432";
my $db_name = "targeting";
my $db_username = "rm";
my $db_password = "rm";

sub connectToDb {
    return (DBI->connect_cached("dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port","$db_username","$db_password",
            {PrintError => 1, AutoCommit => 0}) or die "Can't connect to database");
}

sub checkAndInitDbForMedicforum {
    my $db = connectToDb();
    my $sql = "select appid from obj.app where appid = 1004";
    my $sth = $db->prepare($sql);
    $sth->execute();
    my $appid = $sth->fetchrow_hashref();
    if (!defined $appid){
        if (defined $sth->err){
            die "error : ".$sth->errstr;
        }
        #insert new application string
        my $insert_sql = "insert into obj.app (appid, name, deleted) values (1004, 'MEDICFORUM', false)";
        eval{
            $db->do($insert_sql);
            $db->commit();
        };
        if ($@){
            die "Transaction aborted because $@";
        }
    }
    $sql = "select id from dict.type where mtype='text'";
    $sth = $db->prepare($sql);
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    my $typeId;
    if (!defined $row){
        if (defined $sth->err){
            die "error : ".$sth->errstr;
        }
        eval{
            $db->do("insert into dict.type (mtype, name, deleted) values ('text', 'Текст', false)");
            $typeId = $db->last_insert_id(undef, 'dict', 'type', undef);
            $db->commit();
        };
        if ($@){
            die "Transaction aborted because $@";
        }
    }else{
        $typeId = $row->{'id'};
    }
    return $typeId;
}


sub insertDataToDb{
    my $dbh = connectToDb();
    my $typeId = checkAndInitDbForMedicforum(); 
    my $dataArray = shift;
    my $insertObjSql = <<SQL;
        INSERT INTO obj.ado (appid, uuid, flink, link_text, short_description, ilink, tid, name, deleted)
        VALUES(1004, uuid_generate_v4(), ?, ?, ?, ?, ?, ?, false) 
SQL
    my $selectObjSql = <<SQL;
        SELECT id FROM obj.ado WHERE name = ?
SQL
    my $insertGroupSql = <<SQL;
        INSERT INTO obj.group (appid, name, attr, weight, priorityid, enable, deleted) 
        VALUES (1004, ?, '', 0, 1, TRUE, FALSE)
SQL
    my $selectGroupSql = <<SQL;
        SELECT id FROM obj.group WHERE name = ?
SQL
    my $insertObjToGrpSql = <<SQL;
        INSERT INTO obj.ado2group (oid, gid, enable) VALUES (?, ?, TRUE);
SQL
    eval{ #transaction block
        my $insertObjSth = $dbh->prepare($insertObjSql);
        my $selectObjSth = $dbh->prepare($selectObjSql);
        my $insertGroupSth = $dbh->prepare($insertGroupSql);
        my $selectGroupSth = $dbh->prepare($selectGroupSql);
        my $insertObjToGrpSql = $dbh->prepare($insertObjToGrpSql);
        for my $vals (@$dataArray){
            $selectObjSth->execute($vals->{'title'});
            my $objrow = $selectObjSth->fetchrow_hashref();
            if (defined $objrow){
                next;
            }
            $insertObjSth->execute($vals->{'link'}, $vals->{'title'}, $vals->{'description'}, $vals->{'img_url'}, $typeId, $vals->{'title'});
            my $objId = $dbh->last_insert_id(undef, 'obj', 'ado', undef);
            print "objId: ".$objId."\n";

            $selectGroupSth->execute($vals->{'category'});
            my $grouprow = $selectGroupSth->fetchrow_hashref();
            my $groupId;
            if (!defined $grouprow){
                $insertGroupSth->execute($vals->{'category'});
                $groupId = $dbh->last_insert_id(undef, 'obj', 'group', undef);
            }else{
                $groupId = $grouprow->{id};
            }
            print "groupId: ".$groupId."\n";

            $insertObjToGrpSql->execute($objId, $groupId);
        }
        $dbh->commit();
    };
    if ($@){
        print "Transaction aborted because $@";
    }
}

sub getDataFromRss {
    my $xml = XML::LibXML->load_xml(location => 'http://www.medikforum.ru/news/rss.xml');
    my $xc = XML::LibXML::XPathContext->new($xml);
    $xc->registerNs("rss2", "http://backend.userland.com/rss2");
    my @items = $xc->findnodes("/rss2:rss/rss2:channel/rss2:item");
    my $records = [];
    for my $item (@items){
        my @children = $item->childNodes();
        my $param = {};
        for my $child (@children){
            if ($child->nodeName eq "title"){
                $param->{'title'} = $child->textContent;
            }
            if ($child->nodeName eq "link"){
                $param->{'link'} = $child->textContent;
            }
            if ($child->nodeName eq "description"){
                $param->{'description'} = $child->textContent;
            }
            if ($child->nodeName eq "category"){
                $param->{'category'} = $child->textContent;
            }
            if ($child->nodeName eq "pubDate"){
                $param->{'date'} = $child->textContent;
            }
            if ($child->nodeName eq "enclosure"){
                $param->{'img_url'} = $child->getAttributeNode("url")->getValue();
            }
        }
        push($records, $param);

    }
    return $records;
}

sub main{
    return insertDataToDb(getDataFromRss());
}

main();
