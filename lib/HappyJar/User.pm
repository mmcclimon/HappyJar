package HappyJar::User;
use warnings;
use strict;
use v5.14;  # for switch

use Moo;
use namespace::clean;

use HappyJar::Auth;

=head1 NAME

HappyJar::User

=head1 SYNOPSIS

This is the class representing a user. Right now it doesn't do much, but it
seemed like there should be one, so there is.

=head1 ATTRIBUTES

=item name

=cut

has 'name'  => ( is => 'ro');

=item email

=cut

has 'email' => ( is => 'ro');

1;

__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>

