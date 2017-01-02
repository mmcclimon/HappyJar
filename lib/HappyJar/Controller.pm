package HappyJar::Controller;
use Mojo::Base 'Mojolicious::Controller';

use HappyJar::Auth;
use HappyJar::Database;
use Try::Tiny;
use DateTime;

=head1 NAME

HappyJar::Controller

=head1 SYNOPSIS

The main controller class for the application.

=head1 METHODS

=over 4

=item index

Renders the index page after ensuring that user is logged in properly. This is
the main page with the form used to create a new memory.

=cut

sub index {
    my $self = shift;
    my $user = $self->_ensure_logged_in();

    my $num_memories = HappyJar::Database->get_num_memories_this_year();

    # figure out the month and day, used in select_field helpers
    my @months = (
        [January => '01'], [February => '02'], [March => '03'], [April => '04'],
        [May => '05'], [June => '06'], [July => '07'], [August => '08'],
        [September => '09'], [October => '10'], [November => '11'], [December => '12'],
    );
    my @days = (1..31);

    # add selected attributes
    my $dt = DateTime->now(time_zone => 'America/Indianapolis');
    my $month = $dt->month() - 1;       # We need an array index
    my $mday = $dt->day();
    push @{$months[$month]}, 'selected' => 'selected';
    $days[$mday - 1] = [$mday => $mday, 'selected' => 'selected'];

    $self->stash(num_memories => $num_memories);
    $self->stash(months => \@months);
    $self->stash(days => \@days);
    $self->render();
}

=item memory

Handles the POST action for adding a new memory to the jar. Gets parameters
'month', 'day', and 'memory' from POST, formats the date and calls
L<HappyJar::Database> to insert the memory into the database. On success,
redirects to C</success>.

=cut

sub memory {
    my $self = shift;
    my $user = $self->_ensure_logged_in();

    my ($month, $day, $memory) = $self->param(['month', 'day', 'memory']);

    # format date: yyyy-mm-dd
    my $date = DateTime->new(year => $self->_current_year(), month => $month,
        day => $day, time_zone => 'America/Indianapolis')->ymd;

    $memory = HappyJar::Database->insert_memory($user, $date, $memory);

    $self->flash(memory => $memory);
    $self->redirect_to('/success');
}

=item memory_success

Renders successful memory posting page.

=cut

sub memory_success { shift->render(); }

=item error

Renders error page (usually from a bad login) using the flash to get an error
message.

=cut

sub error { shift->render(); }

=item login

Renders page with login form

=cut

sub login { shift->render(); }

=item handle_login

Handles the POST to the login page. It gets two parameters, 'name' and
'password' (in plain text) from POST, then calls into L<HappyJar::Auth> to
authenticate them with users we have saved in the database.

On success, sets a week-long cookie so that user doesn't need to log in again
all the time. It then redirects to path in session variable C<redir> if it
exists, and back out to the main index page if it doesn't. On failure,
redirects to error page with a sane message.

=cut

sub handle_login {
    my $self = shift;

    my ($name, $pass) = $self->param(['name', 'password']);

    try {
        my $user = HappyJar::Auth::get_user($name, $pass);

        # set a cookie, expires in a week
        $self->signed_cookie(user => $user->name, {
            expires => time + (60 * 60 * 24 * 7),
        });

        # if user was redirected here this will be set, otherwise we can
        # redirect to the home page
        my $redir = $self->session('redir');

        if ($redir) {
            delete $self->session->{redir};
            $self->redirect_to($redir);
        } else {
            $self->redirect_to('/');
        }
    } catch {
        my $msg = '';

        if    (/bad password/)        { $msg = 'Incorrect password'; }
        elsif (/user does not exist/) { $msg = 'User does not exist.'; }
        else { $msg = $_; }

        $self->flash(msg => $msg);
        $self->res->code(403);
        $self->redirect_to('/error');
    };
}

=item contents

Renders page that shows a listing of all of the happy thoughts. This is a bit
clever, though: if it's still the current year, we don't want to be able to
get to the list (it's a sealed jar), so this will render a page with a snarky
message. If it's not the current year (in the new year, or if there happens to
be a highly bizarre calendar event) this will render a table of all of the
memories.

=cut

sub contents {
    my $self = shift;

    my $yearWanted = $self->stash('year');
    my $currentYear = $self->_current_year();

    if ($yearWanted == $currentYear) {
        $self->render(template => 'controller/not_yet');
    } else {
        my $memories = HappyJar::Database->get_all_memories_for_year($yearWanted);
        $self->stash(memories => $memories);
        $self->render(template => 'controller/contents');
    }
}

=item _ensure_logged_in

If user is logged in, returns their user name. If not, redirects to
login page and sets a session variable 'redir' with the current path.

=cut

sub _ensure_logged_in {
    my $self = shift;
    my $user = $self->signed_cookie('user');
    return $user if $user;

    my $path = $self->req->url->path;

    $self->session(redir => $path);
    $self->redirect_to('/login');
}

=item _current_year

Returns current year.

=cut

sub _current_year {
    return (localtime())[5] + 1900;
}

1;


__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>
