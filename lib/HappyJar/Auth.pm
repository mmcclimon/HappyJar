package HappyJar::Auth;
use warnings;
use strict;

use HappyJar::Database;
use HappyJar::User;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);

# private vars
my $salt = 'Michael&Carolyn!';
my $dbh;

# Hashes password using C<bcrypt>.
sub hash_password {
    my $pass= shift;
    my $hash = bcrypt_hash({key_nul => 1, cost => 8, salt => $salt}, $pass);
    my $hash64 = en_base64($hash);
    return $hash64;
}

# gets a username/password, returns a HappyJar::User object or dies
sub get_user {
    my ($user, $pass) = @_;
    my $input_hash = hash_password($pass);

    my ($db_user, $db_email, $db_hash) = _get_user_data_for($user);

    die 'user does not exist' unless $db_user;
    die 'bad password' if ($input_hash ne $db_hash);

    # if we don't die, then everything is ok: create the user
    return HappyJar::User->new(name => $db_user, email => $db_email);
}

# gets user name, retrieves data from db
# returns 0 for all if no rows retrieved
sub _get_user_data_for {
    my $name = shift;

    $dbh ||= HappyJar::Database::connect();

    my $sth = $dbh->prepare(q{SELECT * FROM users WHERE name = ?});
    $sth->execute($name);

    if ($sth->rows == 0) {
        return 0, 0, 0;
    }

    my $data = $sth->fetchrow_hashref();
    return $data->{name}, $data->{email}, $data->{password};
}

1;
