package OpenCloset::Donation::Status;

use utf8;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw($NULL $WAITING $DELIVERING $DELIVERED $RETURN_REQUESTED $RETURNING $RETURNED $CANCEL $DO_NOT_RETURN $REGISTERED);

our $NULL             = '';
our $WAITING          = 'waiting';
our $DELIVERING       = 'delivering';
our $DELIVERED        = 'delivered';
our $RETURN_REQUESTED = 'return-requested';
our $RETURNING        = 'returning';
our $RETURNED         = 'returned';
our $CANCEL           = 'cancel';
our $DO_NOT_RETURN    = 'do-not-return';
our $REGISTERED       = 'registered';

our $LABEL_NULL             = '신청됨';
our $LABEL_WAITING          = '발송대기';
our $LABEL_DELIVERING       = '배송중';
our $LABEL_DELIVERED        = '배송완료';
our $LABEL_RETURN_REQUESTED = '반송신청';
our $LABEL_RETURNING        = '반송중';
our $LABEL_RETURNED         = '반송완료';
our $LABEL_CANCEL           = '취소';
our $LABEL_DO_NOT_RETURN    = '반송안함';
our $LABEL_REGISTERED       = '등록됨';

our @ALL = ( $NULL, $WAITING, $DELIVERING, $DELIVERED, $RETURN_REQUESTED, $RETURNING, $RETURNED, $CANCEL, $DO_NOT_RETURN, $REGISTERED );
our @ALL_LABEL = (
    $LABEL_NULL,   $LABEL_WAITING,       $LABEL_DELIVERING, $LABEL_DELIVERED, $LABEL_RETURN_REQUESTED, $LABEL_RETURNING, $LABEL_RETURNED,
    $LABEL_CANCEL, $LABEL_DO_NOT_RETURN, $LABEL_REGISTERED
);

our %LABEL_MAP = (
    $NULL             => $LABEL_NULL,
    $WAITING          => $LABEL_WAITING,
    $DELIVERING       => $LABEL_DELIVERING,
    $DELIVERED        => $LABEL_DELIVERED,
    $RETURN_REQUESTED => $LABEL_RETURN_REQUESTED,
    $RETURNING        => $LABEL_RETURNING,
    $RETURNED         => $LABEL_RETURNED,
    $CANCEL           => $LABEL_CANCEL,
    $DO_NOT_RETURN    => $LABEL_DO_NOT_RETURN,
    $REGISTERED       => $LABEL_REGISTERED
);

1;
