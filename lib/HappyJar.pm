package HappyJar;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Router
  my $r = $self->routes;

  $r->get('/')->to('default#index');
}

1;
