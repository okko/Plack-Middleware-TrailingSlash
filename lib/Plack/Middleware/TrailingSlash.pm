package Plack::Middleware::TrailingSlash;
use strict;
BEGIN {
    $Plack::Middleware::TrailingSlash::AUTHORITY = 'cpan:okko';
}
BEGIN {
    $Plack::Middleware::TrailingSlash::VERSION = '0.001';
}
use Moose;
use namespace::autoclean;
use Plack::Request;
use HTML::Entities;

extends 'Plack::Middleware';

has 'ignore' => (is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    my $p = $req->path_info();

    # Ignore if not GET
    if ($req->method() ne 'GET') {
        return $self->app->($env);
    }

    # Ignore if we are happy with the URL
    if ($p =~ /^.*\/$/                    # Slash at the end OR
        or $p =~ /^.*\/[^\/]+\.[^\/]+$/   # dot in the filename after the last /
        ) {
        return $self->app->($env);
    }

    # Ignore if in the ignore list
    if ( defined $self->ignore ) {
	unless ( ref($self->ignore) eq 'ARRAY' ) {
	    warn "not arrayref";
	    $self->ignore( [ $self->ignore ] );
	}

	    foreach my $ign ( @{$self->ignore} ) {
		if ($p =~ $ign) {
		    return $self->app->($env);
		}
	    }
    }

    # If we're here the pattern indicates it is a GET request to a directory path and should have a trailing slash.
    my $uri = $req->uri();
    if ($uri =~ /\?/) {
        # with a query string
        $uri =~ s/\?/\/?/;
    } else {
        # without a query string
        $uri .= '/';
    }
    my $res = $req->new_response(301); # new Plack::Response
    $res->headers([ 'Location' => $uri, 'Content-Type' => 'text/html; charset=UTF-8' ]);
    my $uhe = encode_entities($uri);
    $res->body(
        '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN"><html><head><title>301 Moved Permanently</title></head>'
        .'<body><h1>Moved Permanently</h1><p>The document has moved <a href="'.$uhe.'">here</a>.</p></body></html>'
    );
    return $res->finalize;
};

# If you are certain you don't need to inline your constructor, specify inline_constructor => 0 in your call to Plack::Middleware::TrailingSlash->meta->mak
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
