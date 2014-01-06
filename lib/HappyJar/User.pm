package HappyJar::User;
use warnings;
use strict;
use v5.14;  # for switch

use Moo;
use namespace::clean;

use HappyJar::Auth;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);

# private vars
my $password = '';

has 'name' => (
    is => 'ro',
    isa => sub {
        my $name = shift;
        die 'bad user!' unless $name eq 'michael' || $name eq 'carolyn';
    },
);

has 'email' => (
    is => 'ro',
);


1;
