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

    $dbh = DBI->connect($conn_string, $user, $pass);
}

1;
