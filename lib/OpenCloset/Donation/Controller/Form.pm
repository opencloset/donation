package OpenCloset::Donation::Controller::Form;
use Mojo::Base 'Mojolicious::Controller';

use Data::Pageset;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 list

    # forms
    GET /forms

=cut

sub list {
    my $self = shift;
    my $p = $self->param('p') || 1;

    my $rs = $self->schema->resultset('DonationForm')
        ->search( undef, { page => $p, rows => 20, } );

    my $pager   = $rs->pager;
    my $pageset = Data::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            pages_per_set    => 5,
            current_page     => $p,
        }
    );

    $self->render( forms => $rs, pageset => $pageset );
}

=head2 form

    # form
    GET /forms/:id

=cut

sub form {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    $self->render( form => $form );
}

1;
