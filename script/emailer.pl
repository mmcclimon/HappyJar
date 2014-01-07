#!/usr/bin/env perl
use warnings;
use strict;

=head1 README

This is a script that sends a user an email if it's been more than 4 days
since they last put a memory into the happy jar. It works well, but only
because we're only dealing with two users (it's highly inefficient).

A better way to do this would be to get all of the users and dates in one
database call, but at most we're making 4, so I don't care.

=cut

use lib 'lib';
use HappyJar::User;
use HappyJar::Database;
use HappyJar::Emailer;
use DateTime;

# private variables
my $db = 'HappyJar::Database';
my $emailer = HappyJar::Emailer->new();

main();

sub main {
    # get the users (manually)
    my @users = (get_user('michael'), get_user('carolyn'));

    # loop through, sending email if needed
    for my $user (@users) {

        # figure out how long ago they submitted...
        my $delta = get_last_memory_delta($user);

        # ...and send an email if it was more than 4 days ago.
        if ($delta > 4) {
            my $subject = "A friendly note from the Happy Jar";
            my $msg = get_message($user->name, $delta);
            $emailer->send($user->email, $subject, $msg);
        }
    }
}

# Retrieve a HappyJar::User object from the database given user name
sub get_user {
    my $user = shift;
    my ($name, $email, undef) = $db->get_user_data_for($user);
    return unless $name;

    my $u = HappyJar::User->new(name => $name, email => $email);
    return $u;
}

# Returns number of days since param $user last submitted to happy jar.
sub get_last_memory_delta {
    my $user = shift;
    my $date = $db->get_last_date_for($user->name);

    # make a DateTime from the last date user posted
    my ($y, $m, $d) = $date =~ m/(\d{4})-(\d{2})-(\d{2})/;
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

__END__

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>

