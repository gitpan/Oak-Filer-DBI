package Oak::Filer::DBI;

use base qw(Oak::Filer);
use Error qw(:try);

use strict;

=head1 NAME

Oak::Filer::DBI - Filer to save/load data into/from DBI tables

=head1 DESCRIPTION

This module provides access for saving data into a DBI table, to be used by
a Persistent descendant to save its data. Must pass table, and where

=head1 HIERARCHY

L<Oak::Object|Oak::Object>

L<Oak::Filer|Oak::Filer>

L<Oak::Filer::DBI|Oak::Filer::DBI>


=head1 PROPERTIES

=over

=item io

Mandatory property. Defines the Oak::IO::DBI object that will be used
to communicate with the database. This property contains a reference to
the Oak::IO::DBI object, not the name.

=item table

Mandatory property. Defines the table that this filer will work on.

=item where

Optional. Contains a hashref with the following format
  {primarykey => value}
This will be used to create the custom SQL when fetching data.

=back

=head1 METHODS

=cut

sub constructor {
	my $self = shift;
	my %params = @_;
	$self->set		# Avoid inexistent properties
	  (
	   io => $params{io},
	   where => $params{where},
	   table => $params{table},
	  );
	$self->get('io') || throw Oak::Error::ParamsMissing;
}


=over

=item load(FIELD,FIELD,...)

Loads one or more properties of the selected DBI table with the selected WHERE statement.
Returns a hash with the properties.

see Oak::IO::DBI::do_sql for possible exceptions.

=back

=cut

sub load {
	my $self = shift;
	my $table = $self->get('table');
	my $where = $self->make_where_statement;
	return {} unless $table && $where;
	my @props = @_;
	my $fields = join(',',@props);
	my $sql = "SELECT $fields FROM $table WHERE $where";
	my $sth = $self->get('io')->do_sql($sql);
	return () unless $sth->rows;
	return %{$sth->fetchrow_hashref};
}

=over

=item store(FIELD=>VALUE,FIELD=>VALUE,...)

Saves the data into the selected table with the selected WHERE statement.

see Oak::IO::DBI::do_sql for possible exceptions.

=back

=cut

sub store {
        my $self = shift;
        my $table = $self->get('table');
        my $where = $self->make_where_statement;
        return 0 unless $table && $where;
        my %args = @_;
        my @fields;
        foreach my $p (keys %args) {
                $args{$p} = $self->get('io')->quote($args{$p});
                push @fields, "$p=$args{$p}"
        }
        my $set = join(',', @fields);
        my $sql = "UPDATE $table SET $set WHERE $where";
        $self->get('io')->do_sql($sql);
        return 1;
}

=over

=item insert(FIELD=>VALUE,FIELD=>VALUE,...)

Insert a register in the selected table with the data
in the parameters

see Oak::IO::DBI::do_sql for possible exceptions.

=back

=cut

sub insert {
	my $self = shift;
	my $table = $self->get('table');
	return 0 unless $table;
	my %args = @_;
	my @fields;
	my $sql;
	foreach my $p (keys %args) {
		$args{$p} = $self->get('io')->quote($args{$p});
		push @fields, "$p=$args{$p}"
	}

	my $set = join(',', @fields);

	$sql = "INSERT INTO $table SET $set";
	my $sth = $self->get('io')->do_sql($sql);
	return $sth;
}

=over

=item delete

Delete the entry from the table

see Oak::IO::DBI::do_sql for possible exceptions.

=back

=cut

sub delete {
        my $self = shift;
        my $table = $self->get('table');
        my $where = $self->make_where_statement;
        return 0 unless $table && $where;
        my $sql = "DELETE FROM $table WHERE $where";
        $self->get('io')->do_sql($sql);
        return 1;
}

#internal function
sub make_where_statement {
	my $self = shift;
	my $where;
	my @fields;
	my $hr_where = $self->get('where');
	return 0 unless ref $hr_where;
	foreach my $w (keys %{$hr_where}) {
		push @fields, $w."=".$self->get('io')->quote($hr_where->{$w});
	}
	return join(' AND ',@fields);
}

=over

=item begin_work, commit, rollback

Calls the method with the same name at DBI.

=back

=cut

sub begin_work {
	my $self = shift;
	$self->get('io')->begin_work;
	return 1;
}

sub commit {
	my $self = shift;
	$self->get('io')->commit;
	return 1;
}

sub rollback {
	my $self = shift;
	$self->get('io')->rollback;
	return 1;
}



1;

__END__

=head1 EXAMPLES

  require Oak::Filer::DBI;

  my $filer = new Oak::Filer::DBI
   (
    io => $iodbiobj,		# mandatory, an Oak::IO::DBI object.
    table => "tablename",	# mandatory to enable load and store.
				#   table to work in selects and updates
    where => {primary => value},# this is optional, once itsn't passed 
				# you assumes that u're creating a new object
   )
    
  my $nome = $filer->load("nome");
  $filer->store(nome => lc($nome));

=head1 COPYRIGHT

Copyright (c) 2001 Daniel Ruoso <daniel@ruoso.com> and Rodolfo Sikora <rodolfo@trevas.net>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

