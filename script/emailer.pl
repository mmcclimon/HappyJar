#!/usr/bin/env perl
use warnings;
use strict;

=head1 README

This is a script that sends a user an email if it's been more than 4 days
since they last put a memory into the happy jar.

=cut

use lib 'lib';
use HappyJar::User;
use HappyJar::Database;
use HappyJar::Emailer;
use DateTime;

# private variables
my $emailer = HappyJar::Emailer->new();

main();

sub main {
    print "Starting email script...\n";
    my @users = get_users();

    my $num_emailed = 0;

    # loop through, sending email if needed
    for my $user (@users) {

        # figure out how long ago they submitted...
        my $delta = get_last_memory_delta($user);

        # ...and send an email if it was more than 4 days ago.
        if ($delta > 4) {
            my $subject = "A friendly note from the Happy Jar";
            my $msg = get_message($user->name, $delta);
            $emailer->send($user->email, $subject, $msg);
            write_to_log($user);
            $num_emailed++;
        }
    }
    print "Finishing email script...emailed $num_emailed users.\n";
}

# Retrieve an array of HappyJar::User objects from the database.
sub get_users {
    my @users;

    my $data = HappyJar::Database->get_last_dates();
    for my $row (@$data) {
        my ($name, $email, $date) = @$row;
        next unless $name;
        push @users, HappyJar::User->new(
            name => $name,
            email => $email,
            last_entry_date => $date,
        );
    }

    return @users;
}

# Returns number of days since param $user last submitted to happy jar.
sub get_last_memory_delta {
    my $user = shift;

    # make a DateTime from the last date user posted
    my ($y, $m, $d) = $user->last_entry_date =~ m/(\d{4})-(\d{2})-(\d{2})/;
    my $dt = DateTime->new(
        year => $y,
        month => $m,
        day => $d,
        time_zone => 'America/Indianapolis',
    );

    # calculate the delta in days
    my $now = DateTime->now(time_zone => 'America/Indianapolis');
    my $dur = $now->delta_days($dt)->in_units('days');
    return $dur;
}

# The actual message we're sending, personalized with name and number of days
# since last update.
sub get_message {
    my ($name, $num_days) = @_;
    $name = ucfirst $name;

    my $msg = <<eof;
Hello there $name!

It looks like you've been remiss in your happy-jarring...it's been more than
$num_days days! Please put something in or our happy jar will be sadly empty.

http://happyjar.herokuapp.com

Love,
The Happy Jar Administration Team
eof
}

# Write some stuff to STDOUT so we know what we sent
sub write_to_log {
    my ($user) = @_;
    print "Attempted to email ${\$user->name} at ${\$user->email}, last " .
            "submitted ${\$user->last_entry_date}.\n";
}

__END__

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>

