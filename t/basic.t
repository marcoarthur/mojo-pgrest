use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('UbaJobs');
$t->get_ok('/api')->status_is(200);
$t->delete_ok('/api/users?email=eq.arthurpbs@gmail.com');
$t->post_ok(
    '/api/users' => json => {
        first_name  => 'Marco',
        middle_name => 'Arthur',
        last_name   => 'Silva',
        birthday    => '1981-11-26',
        email       => 'arthurpbs@gmail.com',
    }
)->status_is(201);

$t->get_ok('/api/users?email=eq.arthurpbs@gmail.com')
->status_is(200)
->json_is( '/0/email' => 'arthurpbs@gmail.com' )
->json_is( '/0/first_name' => 'Marco' )
->json_is( '/0/last_name'  => 'Silva' );

done_testing();
