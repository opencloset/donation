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
    my $p    = $self->param('p') || 1;
    my $s    = $self->param('s') || undef;

    my $rs = $self->schema->resultset('DonationForm')
        ->search( { status => $s }, { page => $p, rows => 20, order_by => { -desc => 'update_date' } } );

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

=head2 update_form

    # form.update
    POST /forms/:id

=cut

sub update_form {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $v = $self->validation;
    $v->optional('parcel-service');
    $v->optional('waybill')->like(qr/^\d+$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $parcel_service = $v->param('parcel-service');
    my $waybill        = $v->param('waybill');

    $form->update( { parcel_service => $parcel_service, waybill => $waybill, status => 'sent' } );
    $self->redirect_to('form');
}

1;
