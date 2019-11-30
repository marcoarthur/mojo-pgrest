package UbaJobs::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use DDP;

# TODO: why is not validating ? The pgREST swagger spec seems flawed

# TODO: analyse code repetition
sub new_user ($self) {

    my $c = $self->openapi->valid_input or return;
    $c->render_later;

    my $new = $self->validation->output;
    $new = $new->{users} || {};

    $self->pg( 'POST', '/users', $new )->then(
        sub($tx) {
            my $res = $tx->result;

            if ( $res->code == 201 ) {
                $self->render( openapi => $new, status => 201 );
            } else {
                p $res->json;
                $self->render( json => $res->json, status => $res->code );
            }
        }
    )->catch(
        sub ($err) {
            warn "Error saving new user:  $err";
        }
    );
}

sub del_user( $self ) {
    my $c      = $self->openapi->valid_input or return;
    $c->render_later;

    # Since pgREST accepts table wise operation, we must carefully analyse to
    # check if we have the pk
    # https://postgrest.org/en/v6.0/api.html#deletions
    my $params = $self->validation->output;
    unless ( $params->{email} ) {
        $c->render( text => 'Not permmitted', status => 400 );
        return;
    }

    $params = $self->_params_rewrite( $params );

    # proxy to postgREST. There is a big problem that delete never
    # send error code, only 204, in both, success or failure,
    # http://localhost:3000/api#tag/users/paths/~1users/delete
    $self->pg( 'DELETE', '/users', $params )->then(
        sub($tx) {
            my $res = $tx->result;

            if ( $res->code == 204 ) {
                $self->render( text => "User deleted\n\n" );
            } else {
                # We never reach here.
                $self->render( json => $res->json, status => $res->code );
            }
        }
    )->catch(
        sub ($err) {
            warn "Error deleting user:  $err";
        }
    );
}

sub list_user ( $self ) {
    my $c      = $self->openapi->valid_input or return;
    $c->render_later;

    my $params = $self->_params_rewrite( $self->validation->output );
    $self->pg( 'GET', '/users', $params )->then(
        sub($tx) {
            my $res = $tx->result;
            if ( $res->code == 200 ) {
                $self->render( json => $res->json, status => $res->code );
            } else {
                $self->render( json => $res->json, status => $res->code );
            }
        }
    )->catch(
        sub ($err) {
            warn "Error listing user:  $err";
        }
    );
}

# turn into pgREST query language
sub _params_rewrite( $self, $params ) {
    my $p = {};
    for my $k ( keys %$params ) { 
        $p->{$k} = 'eq.' . $params->{$k};
    }
    return $p;
}

1;
