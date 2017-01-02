package HappyJar;
use Mojo::Base 'Mojolicious';
use v5.10;

=head1 NAME

HappyJar

=head1 SYNOPSIS

This is the main Mojolicious package for this application.

=head1 DESCRIPTION

A happy jar is a jar that one or more people put happy thoughts into, usually
over the course of a whole year. These thoughts are kept secret until the end
of the year, when they are revealed as a retrospective of the good things that
happened.

This is a digital version of that...it's running online at
L<http://happyjar.herokuapp.com>, though unless you log in there's not much to
look at.

=head1 METHODS

=over4

=item startup

This method is run once at server start, and sets application settings and
routes.

=cut

sub startup {
    my $self = shift;

    $self->secrets(['Oh, happiest of jars!']);

    $self->hook(before_dispatch => \&redirect_to_https);

    # Router
    my $r = $self->routes;

    $r->get('/')->to('controller#index');
    $r->get('/login')->to('controller#login');
    $r->post('/login')->to('controller#handle_login');
    $r->post('/new')->to('controller#memory');
    $r->get('/success')->to('controller#memory_success');
    $r->get('/error')->to('controller#error');
    $r->get('/contents/:year' => [year => qr/20\d\d/])->to('controller#contents');
}

=item redirect_to_https

Because the app sends passwords, we'll redirect everything on the live server
to HTTPS. Developing locally this won't matter, so HTTP is fine. This is run
as a hook before dispatching routes.

=cut

sub redirect_to_https {
    # gets the default controller as a parameter
    my $c = shift;

    no warnings qw(uninitialized);

    # set the HTTPS header correctly if it's forwarded
    $c->req->url->base->scheme('https') if
        $c->req->headers->header('x-forwarded-proto') eq 'https';

    my $url = $c->req->url;

    # if we're on 'localhost', HTTP is fine
    my $host = $url->base->host || '';
    return if lc $host eq 'localhost';

    # otherwise, try to redirect to https
    my $scheme = $url->base->scheme;
    return if lc $scheme eq 'https';

    # reconstruct url
    my $new = $url->base->clone();
    $new->scheme('https');
    $new->path($url->path);
    $new->query($url->query);
    $new->fragment($url->fragment);

    $c->redirect_to($new->to_string);
}

1;

__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2017 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>
