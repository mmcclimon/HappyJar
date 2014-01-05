#!/usr/bin/env perl
use warnings;
use strict;
use v5.14;

use lib 'lib';

use HappyJar::Database;

my $dbh = HappyJar::Database::connect();

my $stmt = q{
  CREATE TABLE memories (
    id      serial PRIMARY KEY,
    name    char NOT NULL,
    date    date,
    memory  varchar(1000)
  )
};

my $create = $dbh->prepare($stmt);
$create->execute();

