package HappyJar::Controller;
use Mojo::Base 'Mojolicious::Controller';

use HappyJar::User;
use Try::Tiny;

# This action will render a template
sub index {
    my $self = shift;
    $self->render(text => "Hello world!");
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

        $self->render(text => $user->name);
    } catch {
        my $msg = '';

        if    (/bad password/)        { $msg = 'bad password'; }
        elsif (/user does not exist/) { $msg = 'bad user'; }
        else { $msg = $_; }

        $self->render(text => "caught error: $msg");
    };
}

sub env {
    my $self = shift;
    $self->render(inline => '<pre><%= dumper $self->tx->req %></pre>');
}

1;
