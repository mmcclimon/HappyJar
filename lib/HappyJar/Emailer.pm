package HappyJar::Emailer;
use warnings;
use strict;

=head1 NAME

HappyJar::Emailer

=head1 SYNOPSIS

A wrapper around email sending; handles SMTP connection to Sendgrid and the
actual sending of messages.

=cut

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::Simple;
use Email::Simple::Creator;

use Moo;
use namespace::clean;


my $transport;

# set transport (Sendgrid's SMTP) when we create an object
sub BUILD {
    my $self = shift;
    $transport = Email::Sender::Transport::SMTP->new({
        host => 'smtp.sendgrid.net',
        port => '587',
        sasl_username => $ENV{SENDGRID_USERNAME},
        sasl_password => $ENV{SENDGRID_PASSWORD},
    });
}

=head1 METHODS

=over 4

=item send

Pass an email address, subject, and message body. This sends that message from
'Happy Jar <noreply@mcclimon.org>'. Doesn't return anything useful.

=cut

sub send {
    my ($self, $address, $subject, $msg) = @_;

    my $email = Email::Simple->create(
        header => [
            To      => $address,
            From    => 'Happy Jar <noreply@mcclimon.org>',
            Subject => $subject,
        ],
        body => "$msg\n",
    );

    sendmail($email, { transport => $transport });
}

1;

__END__

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClimon

Licensed under the same terms as Perl itself:
L<http://www.perlfoundation.org/artistic_license_2_0>
