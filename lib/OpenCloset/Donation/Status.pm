package OpenCloset::Donation::Status;

use utf8;

our $NULL       = '';
our $WAITING    = 'waiting';
our $DELIVERING = 'delivering';
our $RETURNED   = 'returned';
our $CANCEL     = 'cancel';
our $DISCARD    = 'discard';
our $REGISTERED = 'registered';

our $LABEL_NULL       = '신청됨';
our $LABEL_WAITING    = '발송대기';
our $LABEL_DELIVERING = '배송중';
our $LABEL_RETURNED   = '반송완료';
our $LABEL_CANCEL     = '취소';
our $LABEL_DISCARD    = '폐기';
our $LABEL_REGISTERED = '등록됨';

our @ALL = ( $NULL, $WAITING, $DELIVERING, $RETURNED, $CANCEL, $DISCARD, $REGISTERED );
our @ALL_LABEL = (
    $LABEL_NULL,   $LABEL_WAITING, $LABEL_DELIVERING, $LABEL_RETURNED,
    $LABEL_CANCEL, $LABEL_DISCARD, $LABEL_REGISTERED
);

our %LABEL_MAP = (
    $NULL       => $LABEL_NULL,
    $WAITING    => $LABEL_WAITING,
    $DELIVERING => $LABEL_DELIVERING,
    $RETURNED   => $LABEL_RETURNED,
    $CANCEL     => $LABEL_CANCEL,
    $DISCARD    => $LABEL_DISCARD,
    $REGISTERED => $LABEL_REGISTERED
);

1;
