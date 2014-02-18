package ReachMedia::EncodeUtils;

use strict;
use warnings;
use MIME::Base64;
use Data::MessagePack;

our(@ISA, @EXPORT);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw(responseOK responseError decodeUserContext encodeUserContext encodeBase64MessagePack decodeBase64MessagePack);
}

sub responseError {
    my $errorMessage = shift;
    my $resp = Plack::Response->new(500);
    $resp->content_type('text/html; charset=utf-8');
    $resp->body($errorMessage);
}

sub responseOK {
    my $messageBody = shift;
    my $resp = Plack::Response->new(200);
    $resp->content_type('application/json; charset=utf-8');
    $resp->body($messageBody);
    return $resp->finalize();
}

#there must be 3 parameters: appId, userContext and amount
#userContext is a binary serialized hash (serialized with MessagePack)
#encoded in base64
sub decodeUserContext {
    return decodeBase64MessagePack(@_);
}

sub encodeUserContext {
    return encodeBase64MessagePack(@_);
}

sub decodeBase64MessagePack {
    my $encodedContext = shift;
    my $decodedContext = decode_base64($encodedContext);
    my $packer = new Data::MessagePack;
    return $packer->unpack($decodedContext);
}

sub encodeBase64MessagePack {
    my $context = shift;
    my $packer = new Data::MessagePack;
    my $packedContext = $packer->pack($context);
    return encode_base64($packedContext);
}

1;
