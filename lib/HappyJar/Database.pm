package HappyJar::Database;
use warnings;
use strict;

use DBI;

=head1 SUMMARY

This package provides access to the database.

=cut

# Variables
my $dbh;        # database handle

=head2 METHODS

=over 4

=item connect

Connects to the Postgres database using L<DBI> and the environment variable
C<DATABASE_URL>. Returns database handle.

=cut

sub connect {
    return $dbh if $dbh;

    my $db_url = $ENV{DATABASE_URL};
    die "DATABASE_URL not defined" unless defined $db_url;

    my ($user, $pass, $host, $port, $dbname) =
        $db_url =~ m{postgres://
                     (.+?)      # username: anything, followed by colon
                     (?:        # don't capture - password optional
                       :(.+?)   # password: anything beginning with a colon
                     )?         # end non-capture - password
                     \@         # a literal '@'
                     (.+?)      # hostname: anything, followed by colon
                     (?:        # don't capture - port is optional
                       :(\d+?)  # port: digits, followed by slash
                     )?         # end non-capture - port
                     /          # literal slash
                     (.*?)$     # dbname:   anything up to end of string
                    }gx;

    # developing locally won't have port or password, set these explicitly to
    # empty string to avoid uninitialized warnings
    $pass ||= '';
    $port ||= '';

    my $conn_string = "dbi:Pg:dbname=$dbname;host=$host";
    $conn_string .= ";port=$port" if $port;

    $dbh = DBI->connect($conn_string, $user, $pass, {
        RaiseError => 1,
        AutoCommit => 1,
    });
}

=item get_user_data_for

Retrieve user name, email, and password hash from database, given a user name.
Returns 0 for all elements if user does not exist in database.

=cut

sub get_user_data_for {
    my ($self, $name) = @_;
    $self->connect();

    my $sth = $dbh->prepare(q{SELECT * FROM users WHERE name = ?});
    $sth->execute($name);

    if ($sth->rows == 0) {
        return 0, 0, 0;
    }

    my $data = $sth->fetchrow_hashref();
    return $data->{name}, $data->{email}, $data->{password};
}

=item insert_memory

Passed a user, date, and memory (in that order), inserts memory into the
database. Returns memory on success, dies on error.

=cut

sub insert_memory {
    my ($self, $user, $date, $memory) = @_;
    $self->connect();

    # the database actually just wants the first character as the name
    $user = substr $user, 0, 1;

    my $query = q{INSERT INTO memories (name, date, memory) VALUES (?, ?, ?)};
    my $sth = $dbh->prepare($query);
    $sth->execute($user, $date, $memory);

    return $memory;
}

1;
