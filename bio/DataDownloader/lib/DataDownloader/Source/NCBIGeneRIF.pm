package DataDownloader::Source::NCBIGeneRIF;

use Moose;
extends 'DataDownloader::Source::FtpBase';

# all - ftp://ftp.ncbi.nih.gov/gene/GeneRIF/generifs_basic.gz

use constant {
    TITLE => "NCBI GeneRIF",
    DESCRIPTION => "GeneRIF from NCBI",
    SOURCE_LINK => "ftp.ncbi.nih.gov",
    SOURCE_DIR => "generif",
    SOURCES => [{
        FILE => "generifs_basic.gz",
        HOST => "ftp.ncbi.nih.gov",
        REMOTE_DIR => "gene/GeneRIF",
        EXTRACT => 1,
    }],
};

1;
