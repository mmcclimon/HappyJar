package HappyJar::Controller;
use Mojo::Base 'Mojolicious::Controller';

use HappyJar::User;
use Try::Tiny;

# This action will render a template
sub index {
    my $self = shift;
    my $user = $self->_ensure_logged_in();

    $user = ucfirst $user;
    $self->render(text => "Hello $user!");
}

sub login { 'login'; }

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
