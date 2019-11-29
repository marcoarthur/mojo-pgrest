use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('UbaJobs');
$t->get_ok('/api')->status_is(200);
$t->delete_ok('/api/users?email=arthurpbs@gmail.com');
$t->post_ok(
    '/api/users' => json => {
        first_name  => 'Marco',
        middle_name => 'Arthur',
        last_name   => 'Silva',
        birthday    => '1981-11-26',
        email       => 'arthurpbs@gmail.com',
    }
)->status_is(201)
->json_is( '/email' => 'arthurpbs@gmail.com' )
->json_is( '/first_name' => 'Marco' )
->json_is( '/last_name' => 'Silva' );

$t->get_ok('/api/users?email=arthurpbs@gmail.com')
->status_is(200)
->json_is('/0/email' => 'arthurpbs@gmail.com');

done_testing();
