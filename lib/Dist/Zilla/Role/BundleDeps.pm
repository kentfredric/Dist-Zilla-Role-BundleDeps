use strict;
use warnings;

package Dist::Zilla::Role::BundleDeps;
BEGIN {
  $Dist::Zilla::Role::BundleDeps::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Role::BundleDeps::VERSION = '0.001000';
}

# ABSTRACT: Automatically add all plugins in a bundle as dependencies


use Moose::Role;

sub _bundle_alias {
  my ($self) = @_;
  my $ns = $self->meta->name;
  if ( $ns =~ /^Dist::Zilla::PluginBundle::(.*$)/ ) {
    return q[@] . $1;
  }
  return $ns;
}

around bundle_config => sub {
  my ( $orig, $self, $section, @rest ) = @_;
  my $myconf;
  for my $param (qw( phase relation )) {
    my $field = 'bundledeps_' . $param;
    next unless exists $section->{payload}->{$field};
    $myconf->{$param} = delete $section->{payload}->{$field};
  }
  $myconf->{phase}    = 'develop'  unless exists $myconf->{phase};
  $myconf->{relation} = 'requires' unless exists $myconf->{relation};
  my (@config) = $self->$orig($section);
  require CPAN::Meta::Requirements;
  my $reqs = CPAN::Meta::Requirements->new();
  for my $item (@config) {
    my ( $name, $module, $conf ) = @{$item};
    my $version = 0;
    $version = $conf->{':version'} if exists $conf->{':version'};
    $reqs->add_string_requirement( $module, $version );
  }
  push @config,
    [
    $self->_bundle_alias . '/::Role::BundleDeps',
    'Prereqs',
    {
      '-phase'        => $myconf->{phase},
      '-relationship' => $myconf->{relation},
      %{ $reqs->as_string_hash }
    }
    ];
  return @config;
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::BundleDeps - Automatically add all plugins in a bundle as dependencies

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

    package blahblahblah;
    use Moose;
    ...
    with 'Dist::Zilla::Role::PluginBundle';
    with 'Dist::Zilla::Role::BundleDeps';

Bam, deps appear now for all plugins returned.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
