package OpenCloset::Donation::Category;

use utf8;

our $BELT      = 'belt';
our $BLOUSE    = 'blouse';
our $COAT      = 'coat';
our $JACKET    = 'jacket';
our $ONEPIECE  = 'onepiece';
our $PANTS     = 'pants';
our $SHIRT     = 'shirt';
our $SHOES     = 'shoes';
our $SKIRT     = 'skirt';
our $TIE       = 'tie';
our $WAISTCOAT = 'waistcoat';
our $MISC      = 'misc';

our $LABEL_BELT      = '벨트';
our $LABEL_BLOUSE    = '블라우스';
our $LABEL_COAT      = '코트';
our $LABEL_JACKET    = '자켓';
our $LABEL_ONEPIECE  = '원피스';
our $LABEL_PANTS     = '팬츠';
our $LABEL_SHIRT     = '셔츠';
our $LABEL_SHOES     = '구두';
our $LABEL_SKIRT     = '스커트';
our $LABEL_TIE       = '타이';
our $LABEL_WAISTCOAT = '조끼';
our $LABEL_MISC      = '기타';

our @ALL = ( $BELT, $BLOUSE, $COAT, $JACKET, $ONEPIECE, $PANTS, $SHIRT, $SHOES, $SKIRT, $TIE, $WAISTCOAT, $MISC );

our @ALL_LABEL = (
    $LABEL_BELT, $LABEL_BLOUSE,    $LABEL_COAT, $LABEL_JACKET, $LABEL_ONEPIECE, $LABEL_PANTS, $LABEL_SHIRT, $LABEL_SHOES, $LABEL_SKIRT,
    $LABEL_TIE,  $LABEL_WAISTCOAT, $LABEL_MISC
);

our %LABEL_MAP = (
    $BELT      => $LABEL_BELT,
    $BLOUSE    => $LABEL_BLOUSE,
    $COAT      => $LABEL_COAT,
    $JACKET    => $LABEL_JACKET,
    $ONEPIECE  => $LABEL_ONEPIECE,
    $PANTS     => $LABEL_PANTS,
    $SHIRT     => $LABEL_SHIRT,
    $SHOES     => $LABEL_SHOES,
    $SKIRT     => $LABEL_SKIRT,
    $TIE       => $LABEL_TIE,
    $WAISTCOAT => $LABEL_WAISTCOAT,
    $MISC      => $LABEL_MISC,
);

our %PRICE = (
    $BELT      => 2000,
    $BLOUSE    => 5000,
    $COAT      => 10000,
    $JACKET    => 10000,
    $ONEPIECE  => 10000,
    $PANTS     => 10000,
    $SHIRT     => 5000,
    $SHOES     => 5000,
    $SKIRT     => 10000,
    $TIE       => 0,
    $WAISTCOAT => 5000,
    $MISC      => 0,
);

1;
