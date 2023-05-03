package FFI::C::Util;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref is_plain_arrayref is_plain_hashref is_ref is_blessed_hashref );
use Sub::Identify 0.05 ();
use Carp ();
use Class::Inspector;
use base qw( Exporter );

our @EXPORT_OK = qw( perl_to_c c_to_perl take owned set_array_count addressof );

# ABSTRACT: Utility functions for dealing with structured C data
# VERSION

=head1 SYNOPSIS

#EXAMPLE: examples/synopsis/util.pl

=head1 DESCRIPTION

This module provides some useful utility functions for dealing with
the various def instances provided by L<FFI::C>

=head1 FUNCTIONS

=head2 perl_to_c

 perl_to_c $instance, \%values;  # for Struct/Union
 perl_to_c $instance, \@values;  # for Array

This function initializes the members of an instance.

=cut

sub perl_to_c ($$)
{
  my($inst, $values) = @_;
  if(is_blessed_ref $inst && $inst->isa('FFI::C::Array'))
  {
    Carp::croak("Tried to initialize a @{[ ref $inst ]} with something other than an array reference")
      unless is_plain_arrayref $values;
    &perl_to_c($inst->get($_), $values->[$_]) for 0..$#$values;
  }
  elsif(is_blessed_ref $inst)
  {
    Carp::croak("Tried to initialize a @{[ ref $inst ]} with something other than an hash reference")
      unless is_plain_hashref $values;
    foreach my $name (keys %$values)
    {
      my $value = $values->{$name};
      $inst->$name($value);
    }
  }
  else
  {
    Carp::croak("Not an object");
  }
}

=head2 c_to_perl

 my $perl = c_to_perl $instance;

This function takes an instance and returns the nested members as Perl data structures.

=cut

sub c_to_perl ($)
{
  my $inst = shift;
  Carp::croak("Not an object") unless is_blessed_ref($inst);
  if($inst->isa("FFI::C::Array"))
  {
    return [map { &c_to_perl($_) } @$inst]
  }
  elsif($inst->isa("FFI::C::Struct"))
  {
    my $def = $inst->{def};

    my %h;
    foreach my $key (keys %{ $def->{members} })
    {
      next if $key =~ /^:/;
      my $value = $inst->$key;
      $value = &c_to_perl($value) if is_blessed_ref $value;
      $value = [@$value] if is_plain_arrayref $value;
      $h{$key} = $value;
    }

    return \%h;
  }
  elsif($inst->isa('FFI::C::Buffer'))
  {
    return $inst->to_perl;
  }
  else
  {
    my %h;
    my $df = $INC{'FFI/C/StructDef.pm'};
    foreach my $key (@{ Class::Inspector->methods(ref $inst) })
    {
      next if $key =~ /^(new|DESTROY)$/;

      # we only want to recurse on generated methods.
      my ($file) = Sub::Identify::get_code_location( $inst->can($key) );
      next unless $file eq $df;

      # get the value;
      my $value = $inst->$key;
      $value = &c_to_perl($value) if is_blessed_hashref $value;
      $value = [@$value] if is_plain_arrayref $value;
      $h{$key} = $value;
    }

    return \%h;
  }
}

=head2 owned

 my $bool = owned $instance;

Returns true of the C<$instance> owns its allocated memory.  That is,
it will free up the allocated memory when it falls out of scope.
Reasons an instance might not be owned are:

=over 4

=item the instance is nested inside another object that owns the memory

=item the instance was returned from a C function that owns the memory

=item ownership was taken away by the C<take> function below.

=back

=cut

sub owned ($)
{
  my $inst = shift;
  !!($inst->{ptr} && !$inst->{owner});
}

=head2 take

 my $ptr = take $instance;

This function takes ownership of the instance pointer, and returns
the opaque pointer.  This means a couple of things:

=over 4

=item C<$instance> will not free its data automatically

You should call C<free> on it manually to free the memory it is using.

=item C<$instance> cannot be used anymore

So don't try to get/set any of its members, or pass it into a function.

=back

The returned pointer can be cast into something else or passed into
a function that takes an C<opaque> argument.

=cut

sub take ($)
{
  my $inst = shift;
  Carp::croak("Not an object") unless is_blessed_ref $inst;
  Carp::croak("Object is owned by someone else") if $inst->{owner};
  my $ptr = delete $inst->{ptr};
  Carp::croak("Object pointer went away") unless $ptr;
  $ptr;
}

=head2 addressof

[version 0.11]

 my $ptr = addressof $instance;

This function returns the address (as an C<opaque> type) of the
instance object.  This is similar to C<take> above in that it gets
you the address of the object, but doesn't take ownership of it,
so care needs to be taken when using C<$ptr> that the object
is still allocated.

=cut

sub addressof ($)
{
  my $inst = shift;
  Carp::croak("Not an object") unless is_blessed_ref $inst;
  my $ptr = $inst->{ptr};
  Carp::croak("Object pointer went away") unless $ptr;
  $ptr;
}

=head2 set_array_count

 set_array_count $inst, $count;

This function sets the element count on a variable array returned from
C (where normally there is no way to know from just the return value).
If you try to set a count on a non-array or a fixed sized array an
exception will be thrown.

=cut

sub set_array_count ($$)
{
  my($inst, $count) = @_;
  Carp::croak("Not a FFI::C::Array")
    unless is_blessed_ref $inst && $inst->isa('FFI::C::Array');
  Carp::croak("This array already has a size")
    if $inst->{count};
  $inst->{count} = $count;
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::ASCIIString>

=item L<FFI::C::Buffer>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::String>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut
