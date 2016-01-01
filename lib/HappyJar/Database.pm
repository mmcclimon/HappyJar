package HappyJar::Database;
use warnings;
use strict;

use DBI;

=head1 NAME

HappyJar::Database

=head1 SUMMARY

This package provides access to the database.

=cut

# Variables
my $dbh;        # database handle
my $currentYear;

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
        pg_enable_utf8 => 1,
    });

    # set the current year, for use later
    $currentYear = (localtime())[5] + 1900;
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

=item get_num_memories_this_year

Returns the number of memories in the database for the current year.

=cut

sub get_num_memories_this_year {
    my $self = shift;
    $self->connect();

    my $query = q{SELECT COUNT(*) FROM memories WHERE date >= ?};
    my $sth = $dbh->prepare($query);
    $sth->bind_param(1, "$currentYear-01-01");
    $sth->execute();

    return $sth->fetchrow_arrayref->[0];
}


=item insert_memory

Passed a user, date, and memory (in that order), inserts memory into the
database. Returns memory on success, dies on error.

=cut

sub insert_memory {
    my ($self, $user, $date, $memory) = @_;
    $self->connect();

    my $query = q{INSERT INTO memories (name, date, memory) VALUES (?, ?, ?)};
    my $sth = $dbh->prepare($query);
    $sth->execute($user, $date, $memory);

    return $memory;
}

=item get_all_memories_for_year

Retrieves all memories from database for a given year and returns the whole
thing and returns them all in a big arrayref, with columns 'name', 'date', and
'memory'.

=cut

sub get_all_memories_for_year {
    my $self = shift;
    my ($year) = @_;
    $self->connect();

    my $query = q{
        SELECT name, date, memory FROM memories
        WHERE (date >= ? AND date < ?)
        ORDER BY date ASC};
    my $sth = $dbh->prepare($query);
    $sth->bind_param(1, "$year-01-01");
    $sth->bind_param(2, ($year + 1) . "-01-01");
    $sth->execute();

    return $sth->fetchall_arrayref();
}

=item get_last_date_for

Returns user data in an arrayref, with columns 'name', 'email', and 'date'.

=cut

sub get_last_dates {
    my ($self) = @_;
    $self->connect();

    my $q = q{
        SELECT u.name, u.email, max(m.date) AS date
        FROM users u INNER JOIN memories m
        ON u.name = m.name
        GROUP BY u.name
    };

    my $sth = $dbh->prepare($q);
    $sth->execute();

    return $sth->fetchall_arrayref();
}


1;

__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>
