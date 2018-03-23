package DataDownloader::Source::PubMed;

use Moose;
extends 'DataDownloader::Source::FtpBase';
use PerlIO::gzip;
use File::Basename;
use autodie qw(open close);
use DataDownloader::Util 'get_ymd';

use constant {
    TITLE => "PubMed",
    DESCRIPTION => "Gene information from PubMed and publications which mention them from NCBI",
    SOURCE_LINK => "http://www.ncbi.nlm.nih.gov/",
    SOURCE_DIR => 'pubmed',
    METHOD => 'FTP',
};

## %NCBI_TAXA = ( 'taxon' => ['from_pat', 'to_pat'] );
my %NCBI_TAXA = ( '3880' => ['MTR_', 'Medtr'] );

sub process_gi_line {
=comment
#tax_id	GeneID	    Symbol	        LocusTag	Synonyms	dbXrefs	chromosome	map_location	description	type_of_gene	Symbol_from_nomenclature_authority	Full_name_from_nomenclature_authority	Nomenclature_status	Other_designations	Modification_date	Feature_type
3880	11405368	MTR_1g092440	MTR_1g092440	-	-	1	-	P-loop nucleoside triphosphate hydrolase superfamily protein	protein-coding	-	-	-	-	20160917	-
3880	11405370	MTR_1g092650	MTR_1g092650	-	-	1	-	enhancer of polycomb-like transcription factor protein	protein-coding	-	-	-	-	20160917	-
3880	11405373	MTR_1g092860	MTR_1g092860	-	-	1	-	RNA-binding (RRM/RBD/RNP motif) family protein, putative	protein-coding	-	-	-	-	20160917	-

Foreach each gene_info line, if NCBI_TAXA matches taxon_id column (1),
use from_pat and to_pat string to perform regex substitution,
update value in LocusTag column (4)
=cut
    my $line = shift;
    my $from_pat = shift;
    my $to_pat = shift;

    my @cols = split /\t/, $line;

    $cols[3] =~ s/^$from_pat/$to_pat/e;
    return join "\t", @cols;
}

my $geneinfo_cleaner = sub {
    my $self = shift;
    my @lines = ();
    my $file = $self->get_destination;
    open( my($fh), '<:gzip', $file);
    $self->debug("Processing PubMed file $file");
    while (<$fh>) {
        my $gi_line = $_;
        for my $taxon_id ( keys %NCBI_TAXA ) {
            $gi_line = process_gi_line($gi_line, $NCBI_TAXA{$taxon_id}[0], $NCBI_TAXA{$taxon_id}[1]) if (/^$taxon_id\t/);
        }
        push @lines, $gi_line;
    }
    close $fh;

    $self->debug("Writing processed buffers to file");
    my $out_file = $self->get_destination_dir->file("gene_info");
    my $out_fh   = $out_file->openw();
    $self->debug("Writing buffer to $out_file");
    $out_fh->print( @lines );
    $self->info("Data available in $out_file");
    unlink $file;
};


sub BUILD {
    my $self = shift;
    my @sources = (
        {
            SUBTITLE => 'NCBI',
            HOST => "ftp.ncbi.nlm.nih.gov",
            REMOTE_DIR => "gene/DATA",
            FILE => "gene2pubmed.gz",
            EXTRACT => 1,
        },
        {
            SUBTITLE => 'NCBI',
            HOST => "ftp.ncbi.nlm.nih.gov",
            REMOTE_DIR => "gene/DATA",
            FILE => "gene_info.gz",
            CLEANER => $geneinfo_cleaner,
        },

    );
    $self->set_sources( [@sources] );
}





