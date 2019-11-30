package UbaJobs;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::JSON qw( encode_json decode_json );
use Mojo::File;
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
}

sub _load_plugins ($self) {

    my $config = $self->plugin('Config');
    $self->secrets( $config->{secrets} );
    my $p = $self->_load_openapi( $config->{openApi} );

}

# Load OpenAPI from postgREST, setting routes
sub _load_openapi ( $self, $url ) {

    # get schema from pgREST, place x-mojo-to refs
    my $json = $self->ua->get($url)->result->json or die "Can't get schema";
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
