package HappyJar::Default;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
  my $self = shift;
  $self->render(text => "Hello world!");
}

sub env {
  my $self = shift;
  $self->render(inline => '<pre><%= dumper $self->tx->req %></pre>');
}

1;
