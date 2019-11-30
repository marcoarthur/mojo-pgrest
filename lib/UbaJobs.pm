package UbaJobs;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::JSON qw( encode_json decode_json );
use DDP;

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

    my $json = $self->ua->get($url)->result->json or die "Can't get schema";
    my $p = $self->plugin( 'OpenAPI' => { url => $json } );

    # TODO: create a format rules for these fields
    ## no critic Subroutines::ProhibitExplicitReturnUndef
    $p->validator->formats->{text}                = sub { return undef };
    $p->validator->formats->{'character varying'} = sub { return undef };

    return $p;
}

1;
