package UbaJobs::Controller::Base;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::URL;
use DDP;

sub pgrest_proxy( $self ) {
    my $c = $self->openapi->valid_input or return;
    $c->render_later;

    my $input   = $c->validation->output;
    my $name    = $c->match->endpoint->name;
    my $method  = $c->req->method;
    my $params  = $c->req->params->to_hash;
    my $json    = $c->req->json;
    my $headers = $c->req->headers;
    my $host    = $c->openapi->spec("/host");
    my $schemes = $c->openapi->spec("/schemes");

    my $uri = Mojo::URL->new;
    $uri->scheme($schemes->[0]);
    $uri->host($host);
    $uri->path($name);
    $uri->query($params) if $params && keys %$params > 0;

    # proxy to pgREST
    my $tx =
        $json && keys %$json
      ? $c->ua->build_tx( $method => $uri => json => $json )
      : $c->ua->build_tx( $method => $uri );

    # copy auth headers
    $tx->req->headers->authorization($headers->authorization);
    $tx->req->headers->accept('application/json');
    $c->app->log->debug("Calling pgREST ($method): $uri");

    $c->ua->start_p($tx)->then(
        sub( $tx ) {
            my $res = $tx->result;
            $c->render( json => $res->json,    status => $res->code ) if $res->json;
            $c->render( text => 'No response', status => $res->code );
        }
    )->catch( sub( $err ) { warn "Error proxying request:  $err" } );
}

1;
