#!/usr/bin/env perl
use warnings;
use strict;
use v5.14;

use lib 'lib';

use HappyJar::Database;

my $dbh = HappyJar::Database::connect();

# create the constraint
my $stmt = q{
  ALTER TABLE memories
  ADD username varchar(20) REFERENCES users(name)
};
my $restrain = $dbh->prepare($stmt);
$restrain->execute();

# update user records
my $stmt = q{UPDATE memories SET username = ? WHERE name = ? };
my $sth = $dbh->prepare($stmt);
$sth->execute('michael', 'm');
$sth->execute('carolyn', 'c');

# rename column
my $drop = $dbh->prepare(q{ALTER TABLE memories DROP COLUMN name});
$drop->execute();

my $rename = $dbh->prepare(q{ALTER TABLE memories RENAME username TO name});
$rename->execute();

