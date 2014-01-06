package HappyJar::Controller;
use Mojo::Base 'Mojolicious::Controller';

use HappyJar::Auth;
use HappyJar::Database;
use Try::Tiny;
use DateTime;

# This action will render a template
sub index {
    my $self = shift;
    my $user = $self->_ensure_logged_in();

    # figure out the month and day, used in select_field helpers
    my @months = (
        [Jan => '01'], [Feb => '02'], [Mar => '03'], [Apr => '04'],
        [May => '05'], [Jun => '06'], [Jul => '07'], [Aug => '08'],
        [Sep => '09'], [Oct => '10'], [Nov => '11'], [Dec => '12'],
    );
    my @days = (1..31);

    # add selected attributes
    my ($mday, $month) = (localtime(time))[3..4];
    push @{$months[$month]}, 'selected' => 'selected';
    $days[$mday - 1] = [$mday => $mday, 'selected' => 'selected'];

    $self->stash(months => \@months);
    $self->stash(days => \@days);
    $self->render();
}

# handles action for posting a new memory to the happy jar
# gets params 'date' and 'memory'
sub memory {
    my $self = shift;
    my $user = $self->_ensure_logged_in();

    my ($month, $day, $memory) = $self->param(['month', 'day', 'memory']);

    # format date: yyyy-mm-dd
    my $date = DateTime->new(year => 2014, month => $month, day => $day,
        time_zone => 'America/Indianapolis')->ymd;

    $memory = HappyJar::Database->insert_memory($user, $date, $memory);

    $self->flash(memory => $memory);
    $self->redirect_to('/success');
}

sub memory_success { shift->render(); }

# render login template
sub login { shift->render(); }

# gets two POST parameters: 'name' and 'password'
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

        if    (/bad password/)        { $msg = 'bad password'; }
        elsif (/user does not exist/) { $msg = 'bad user'; }
        else { $msg = $_; }

        $self->render(text => "caught error: $msg");
    };
}

# If user is logged in, returns their user name. If not, redirects to
# login page and sets a session variable 'redir' with the current path.
sub _ensure_logged_in {
    my $self = shift;
    my $user = $self->signed_cookie('user');
    return $user if $user;

    my $path = $self->req->url->path;

    $self->session(redir => $path);
    $self->redirect_to('/login');
}

1;
