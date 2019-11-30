package UbaJobs;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::JSON qw( encode_json decode_json );
use Mojo::File;
use URI;
use DDP;

has pg_rest => sub { 'http://localhost:4000' };

sub startup ($self) {
    # set all openapi routes to the proxied pgREST
    $self->hook(
        openapi_routes_added => sub( $openapi, $routes ) {
            for my $route (@$routes) {
                $route->to('base#pgrest_proxy');
            }
        }
    );
    $self->_load_plugins;
    $self->_set_helpers;
}

sub _load_plugins ($self) {

    my $config = $self->plugin('Config');
    $self->secrets( $config->{secrets} );
    my $p = $self->_load_openapi( $config->{openApi} );

}

# helper to call postgREST endpoints
sub _set_helpers ($self) {

    # Handler to build HTTP transaction with postgREST
    #
    # Input:
    #  $c : Mojo::Controller
    #  $method: DELETE | POST | GET ...
    #  $end_point: the pgREST endpoint. '/users' | '/resumes' ...
    #  $args: hash_ref with complementary arguments
    #
    # Output:
    #  $promise: Mojo::Promise for the http transaction
    #
    # TODO: refactor the hole thing, too ugly
    my $pgrest = sub ( $c, $method, $end_point, $args ) {
        my $url = $c->app->pg_rest . $end_point;
        my $tx;

        if ( $method eq 'DELETE' ) {
            $url = URI->new($url);
            $url->query_form($args);
            $tx = $c->ua->build_tx( $method => "$url" );
        } elsif ( $method eq 'POST' ) {
            $tx = $c->ua->build_tx( $method => $url => { Accept => '*/*' } => 'json' => $args );
        } elsif ( $method eq 'GET' ) {
            $url = URI->new($url);
            $url->query_form($args);
            $tx = $c->ua->build_tx( $method => "$url" );
        }
        else {
            $c->app->log->debug("Not Implemented, error");
            return;
        }

        $c->app->log->debug("pgREST ($method): $url");
        return $c->ua->start_p($tx);
    };

    $self->helper( pg => $pgrest );
}

# Load OpenAPI from postgREST, setting routes
sub _load_openapi ( $self, $url ) {

    # get schema from pgREST, place x-mojo-to refs
    my $json = $self->ua->get($url)->result->json or die "Can't get schema";
#    $json->{paths}->{'/users'}->{post}->{'x-mojo-to'}   = "base#pgrest_proxy";
#    $json->{paths}->{'/users'}->{delete}->{'x-mojo-to'} = "base#pgrest_proxy";
#    $json->{paths}->{'/users'}->{get}->{'x-mojo-to'} = "base#pgrest_proxy";
#    $json->{paths}->{'/experiences'}->{get}->{'x-mojo-to'} = "base#pgrest_proxy";
#    $json->{paths}->{'/resumes'}->{get}->{'x-mojo-to'} = "base#pgrest_proxy";

    my $p = $self->plugin( 'OpenAPI' => { url => $json } );

    # save the API spec in a file for debugging reasons
    my $fh = Mojo::File->new("./spec.json")->open(">");
    print $fh encode_json($json);
    $fh->close;

    # TODO: create a format rules for these fields
    ## no critic Subroutines::ProhibitExplicitReturnUndef
    $p->validator->formats->{text}                = sub { return undef };
    $p->validator->formats->{'character varying'} = sub { return undef };

    return $p;
}

1;
