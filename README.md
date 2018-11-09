Intensive integration using Web APIs

A recent paper (DOI: 10.1371/journal.pone.0108567) executes a meta-analysis of a few thousand published co-expressed gene sets from Arabidopsis.  They break these co-expression sets into ~20 sub-networks of <200 genes each, that they find consistently co-expressed with one another.  Assume that you want to take the next step in their analysis, and see if there is already information linking these predicted sub-sets into known regulatory networks.  One step in this analysis would be to determine if the co-expressed genes are known to bind to one another.

Take the co-expressed gene list from Table S2 of the supplementary data from their analysis (I have extracted the data as text for you on the course Moodle → a list of AGI Locus Codes).  Using a combination of the dbFetch, the Togo REST API, EBI’s PSICQUIC (IntAct) REST, and/or the DDBJ KEGG REST interface, and the Gene Ontology, find all protein-protein interaction networks that members of that list participate in, and determine which members of this gene list interact with each other.  USE COMMON SENSE FILTERS IN YOUR CODE! (e.g. for species!!!).

TASKS:  

    Create an “InteractionNetwork” Object to contain the members of each network

    Annotate it with any KEGG Pathways the interaction network members are part of

        both KEGG ID and Pathway Name

    Annotate it with the GO Terms associated with the total of all genes in the network

        BUT ONLY FROM THE biological_process part of the GO Ontology!

        Both GO:ID and GO Term Name

    Create a report of which members of the gene list interact with one another, together with the KEGG/GO functional annotations of those interacting members.
