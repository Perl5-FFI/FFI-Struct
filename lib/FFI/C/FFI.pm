package FFI::C::FFI;

use strict;
use warnings;
use FFI::Platypus 1.24;
use base qw( Exporter );

# ABSTRACT: Private module for FFI::C
# VERSION

=head1 SYNOPSIS

 perldoc FFI::C

=head1 DESCRIPTION

This module is private for L<FFI::C>

=cut

our @EXPORT_OK = qw( malloc free memset memcpy_addr );

my $ffi;
BEGIN { $ffi = FFI::Platypus->new( api => 1, lib => [undef] ) };

use constant memcpy_addr => FFI::Platypus->new( lib => [undef] )->find_symbol( 'memcpy' );

sub malloc ($)
{
  $ffi->function( malloc => ['size_t'] => 'opaque' )
      ->call(@_);
}

sub free ($)
{
  $ffi->function( free => ['opaque'] => 'void' )
      ->call(@_);
}

sub memset ($$$)
{
  $ffi->function( memset => ['opaque','int','size_t'] => 'opaque' )
      ->call(@_);
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut
