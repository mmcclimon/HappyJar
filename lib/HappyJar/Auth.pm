package HappyJar::Auth;
use warnings;
use strict;

use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);

# private vars
my $salt = 'Michael&Carolyn!';

# Hashes password using C<bcrypt>.
sub hash_password {
    my $pass= shift;
    my $hash = bcrypt_hash({key_nul => 1, cost => 8, salt => $salt}, $pass);
    my $hash64 = en_base64($hash);
    return $hash64;
}

1;
