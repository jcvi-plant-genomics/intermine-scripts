package DataDownloader::Source::UniProtGOA;

=head1 NAME

DataDownloader::Source::UniProtGOA;

=head1 SYNOPSIS

Download Gene Ontology:
 ftp.geneontology.org/pub/go/ontology/gene_ontology.obo
     > DATA_DIR/go_annotation/GO/DATE/gene_ontology.obo
     link DATA_DIR/go-annotation/GO/DATE/gene_ontology.obo to DATA_DIR/go-annotation/gene_ontology.obo

Download Gene Ontology Annotation from uniprot and parse it for specified organisms
 ftp.ebi.ac.uk/pub/databases/GO/goa/UNIPROT/goa_uniprot_all.gaf.gz
     > DATA_DIR/go-annotation/uniprot/DATE/downloaded_gene_association.goa_uniprot
From downloaded file produce files gene_association_[SUFFIX] (sorted for each taxon)
     link to current directory: DATA_DIR/go-annotation/uniprot/current

=cut

use Moose;
extends 'DataDownloader::Source::FtpBase';
use PerlIO::gzip;
use File::Basename;
use autodie qw(open close);
use DataDownloader::Util 'get_ymd';

use constant {
    TITLE => "GO Annotation",
    DESCRIPTION => "Gene Ontology Assignments from Uniprot and the Gene Ontology Site",
    SOURCE_LINK => "http://www.geneontology.org",
    SOURCE_DIR => "go-annotation",
    METHOD => 'FTP',

};
my %UNIPROT_TAXA = ( '3880' => 'medtr' );
sub field2_of { return [ split( /\t/, shift ) ]->[1] || '' }
my $order = sub { field2_of($a) cmp field2_of($b) };

my $uniprot_cleaner = sub {
    my $self = shift;
    my %lines_for;
    my $file = $self->get_destination;
    open( my($fh), '<:gzip', $file);
    $self->debug("Splitting uniprot GOA file $file");
    while (<$fh>) {
        for my $taxon_id ( keys %UNIPROT_TAXA ) {
            push @{ $lines_for{$taxon_id} }, $_
                if (/\ttaxon\:$taxon_id\t/);
        }
    }
    close $fh;
    $self->debug("Writing extracted buffers to files");
    while (my ($taxon, $suffix) = each %UNIPROT_TAXA) {
        if ($lines_for{$taxon}) {
            my $sep_file = $self->get_destination_dir->file("gene_association_$suffix");
            $self->debug("Writing buffer for $taxon to $sep_file");
            my $sep_fh   = $sep_file->openw();
            $sep_fh->print( sort( $order @{ $lines_for{$taxon} } ) );
            $self->info("Sorted data for $taxon available in $sep_file");
        } else {
            $self->debug("No data extracted for $taxon");
        }
    }
    unlink $file;
};

my $goa_cleaner = sub {
    my $self = shift;
    $self->unzip_dir();
    my $file = substr( $self->get_destination, 0, -3 );
    $self->debug( "Sorting " . $file );
    open( my $in, '<', $file );
    unlink $file;    # Filter - don't clobber
    open( my $out, '>', $file );
    print $out sort( $order (<$in>) );
};

sub BUILD {
    my $self    = shift;
    my @sources = (
        {
            SUBTITLE   => "GO",
            HOST       => "ftp.geneontology.org",
            REMOTE_DIR => "pub/go/ontology",
            FILE       => "gene_ontology.obo",
        }
    );

    if (%UNIPROT_TAXA) {
        push @sources,
          {
            SUBTITLE   => "uniprot",
            HOST       => "ftp.ebi.ac.uk",
            REMOTE_DIR => "pub/databases/GO/goa/UNIPROT",
            FILE       => "goa_uniprot_all.gaf.gz",
            SUB_DIR    => ["uniprot"],
            CLEANER    => $uniprot_cleaner,
          };
    }
    $self->set_sources( [@sources] );
}

sub generate_version_string {
    my $self = shift;
    my $string = "Version: " . $self->get_version;
    for my $source ($self->get_all_sources) {
        my $ftp = $source->connect;
        my $mod_time = $ftp->mdtm($source->get_file);
        $string .= "\n" . $source->get_file . ": " . get_ymd($mod_time);
    }
    return $string;
}

1;
