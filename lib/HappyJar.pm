package HappyJar;
use Mojo::Base 'Mojolicious';
use v5.10;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->hook(before_dispatch => \&redirect_to_https);

  # Router
  my $r = $self->routes;

  $r->get('/')->to('default#index');
  $r->get('/env')->to('default#env');
}

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
