use Test2::V0 -no_srand => 1;
use FFI::C;
use FFI::Platypus;
use Capture::Tiny qw( capture_merged );

my $ffi = FFI::Platypus->new( api => 1 );

is(
  FFI::C->ffi($ffi),
  object {
    call [ isa => 'FFI::Platypus' ] => T();
  },
  'FFI::C->ffi first set ok',
);

is(
  dies { FFI::C->ffi($ffi) },
  match qr/Already have an FFI::Platypus instance for/,
  'FFI::C->ffi second call dies',
);

is(
  FFI::C->ffi,
  object {
    call [ isa => 'FFI::Platypus' ] => T();
  },
  'FFI::C->ffi can call get as many times as we like',
);

subtest 'example' => sub {

  skip_all 'test requires Perl 5.14 or better' unless $] >= 5.014;

  {
    my($out, $ret) = capture_merged {
        require './examples/synopsis/c.pl';
    };
    is $ret, T(), 'example compiles';
    note $out;
  }

  my $array = ArrayNamedColor->new([
    { name => "red",    value => { red   => 255 } },
    { name => "green",  value => { green => 255 } },
    { name => "blue",   value => { blue  => 255 } },
    { name => "purple", value => { red   => 255,
                                   blue  => 255 } },
  ]);
};

done_testing;
