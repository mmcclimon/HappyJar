package HappyJar::Auth;
use warnings;
use strict;

use HappyJar::Database;
use HappyJar::User;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);

=head1 NAME

HappyJar::Auth

=head1 SYNOPSIS

Deals with authenticating users in the database

=cut

# private vars
my $salt = 'Michael&Carolyn!';
my $db = 'HappyJar::Database';

=head1 METHODS

=over 4

=item hash_password

Gets a plaintext password as a parameter and hashes it using C<bcrypt>.
Returns the base64-encoded hash.

=cut

sub hash_password {
    my $pass= shift;
    my $hash = bcrypt_hash({key_nul => 1, cost => 8, salt => $salt}, $pass);
    my $hash64 = en_base64($hash);
    return $hash64;
}

=item get_user

Used to authenticate a user login. Gets a username and password as parameters.
If they are correct (and the user is valid), this returns a L<HappyJar::User>
object. If not, this will die with a brief message.

=cut

sub get_user {
    my ($user, $pass) = @_;
    my $input_hash = hash_password($pass);

    my ($db_user, $db_email, $db_hash) = $db->get_user_data_for($user);

    die 'user does not exist' unless $db_user;
    die 'bad password' if ($input_hash ne $db_hash);

    # if we don't die, then everything is ok: create the user
    return HappyJar::User->new(name => $db_user, email => $db_email);
}

1;


__END__

=back

=head1 SEE ALSO

L<Crypt::Eksblowfish::Bcrypt>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>
