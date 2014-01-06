#!/usr/bin/env perl
use warnings;
use strict;
use v5.14;

use lib 'lib';
use HappyJar::Database;
use HappyJar::Auth;
use IO::Prompter;

=pod

This is a CLI program to add users to the database. It doesn't do any
validation of anything; if there were more than two users I'd write some, but
there aren't so I won't.

=cut

say 'This program will create users in the database. Ctrl-C to quit whenever';

my $dbh;
create_user_table();

# main user input loop
my $loop = 1;
while ($loop) {
    my ($name, $email, $pass) = prompt_user();
    create_user($name, $email, $pass);
    $loop = prompt "Add another user [y/n]? ", '-yn';
}
say 'Bye-bye.';

# Prompt for user details
sub prompt_user {
    say 'Enter user details:';
    my $name  = prompt 'User name:         ';
    my $email = prompt 'Email:             ';

    my $password;
    $password = get_password() until $password;
    my $stars = '*' x (length $password);

    say "\nReview";
    say   "------";
    say "User:     $name";
    say "Email:    $email";
    say "Password: $stars";

    my $ok = prompt "Ok [y/n]? ", '-yn';
    goto &prompt_user unless $ok;

    return $name, $email, $password;
}

# Prompt for password (in its own function so we can return false if user
# enters two passwords that aren't the same).
sub get_password {
    my $pass1 = prompt 'Password:          ', -echo=>"*";
    my $pass2 = prompt 'Re-enter password: ', -echo => '*';

    if ($pass1 ne $pass2) {
        say 'Two passwords do not match!';
        return 0;
    } else {
        return $pass1;
    }
}

# Actually puts the user into the database.
sub create_user {
    my ($name, $email, $pass) = @_;

    my $hash = HappyJar::Auth::hash_password($pass);

    $dbh ||= HappyJar::Database::connect();

    my $query = q{INSERT INTO users (name, email, password) VALUES (?, ?, ?)};
    my $sth = $dbh->prepare($query);
    $sth->execute($name, $email, $hash);

    say "User '$name' created!\n";
}

# create the user table if it doesn't exist
sub create_user_table {
    $dbh ||= HappyJar::Database::connect();

    my $stmt = q{
      CREATE TABLE IF NOT EXISTS users (
        name        varchar(20) PRIMARY KEY,
        email       varchar(255) NOT NULL,
        password    char(31) NOT NULL
      )
    };

    say "creating user table...";
    my $create = $dbh->prepare($stmt);
    $create->execute();
    say "\n";
}
