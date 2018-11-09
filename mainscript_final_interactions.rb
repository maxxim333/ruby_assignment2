require 'net/http'
require 'json'
require './Protein.rb'
require './Network.rb'


#Open the file
genes = File.read('Name_of_Genes.txt').split("\n")

#Here will be the matrix od proteins
proteins = []
proteins_names = []

#Counter to see where it crashes
i = 0


genes.each do |gene|
  #IDs of proteins of the gene (here may be many protein names of the same protein)
  accessions_uri = URI("http://togows.org/entry/ebi-uniprot/#{gene}/accessions.json")
  
  accessions_text = Net::HTTP.get_response(accessions_uri)
  gene_prot_names = JSON.parse(accessions_text.body).flatten
  
  #GO terms of each gene. This has a lot of info in form of array of arrays
  #but everything is in 0 and GO terms are written in a field called GO
  go_uri = URI("http://togows.org/entry/ebi-uniprot/#{gene}/dr.json")
  go_text = Net::HTTP.get_response(go_uri)
  go_terms = JSON.parse(go_text.body)[0]["GO"]
  #puts go_terms
  
  
  #Select only those that are "biological process". They seem to be
  #the ones that begin with a P. It will have a GO ID and description
  go_hash = Hash.new
  if go_terms
    go_terms.each do |term|
      if term[1][/P:/]
        go_hash[term[0]] = term[1]
      end
    end
  end
  
  
  #Kegg Pathways of genes. It also has an array of array and [0]["pathways"] seems
  #to be what I want
  kegg_uri = URI("http://togows.org/entry/kegg-enzyme/ath:#{gene}.json")
  kegg_text = Net::HTTP.get_response(kegg_uri).body
  kegg_hash = JSON.parse(kegg_text)[0]["pathways"]
  
  
  proteins.push(Protein.new(gene, gene_prot_names, go_hash, kegg_hash))
  proteins_names.push(gene_prot_names)
  i += 1
  puts i
end

#Flatten the array of protein names
proteins_names = proteins_names.flatten

puts "<=====================================================>"

#Interactions. The proteins have a code in IntAct. I want to pick the code of each
#of the proteins then go to the psicquic database and retreive the proteins it
#interacts with. In that database, there is a uniprotkb of the query protein folowed
#by the interacting one, so I have to pick only the interacting one, which will
#be always on the right side, or the second one (regexp will not work here because both begin by uniprotkb)

#These are direct interactions of each protein of the list
interactions = []

proteins.each do |protein|
  protein.name.each do |name|
    interact_uri = URI("http://togows.org/entry/ebi-uniprot/#{name}/dr.json")
    interact_text = Net::HTTP.get_response(interact_uri).body
    data = JSON.parse(interact_text)
    int_act = data[0]["IntAct"]
    if int_act
      int_act.each do |int|
        protein_inter_address = URI("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{int[0]}")
        protein_inter_text = Net::HTTP.get_response(protein_inter_address).body
        proteins_inter_line = protein_inter_text.split("\n").select{|x| /^uniprotkb/.match x}
        proteins_inter_line.each do |line|
          words = line.split("\t")
          prot_id = words[0].split(":")[1]
          
          interactions.push(prot_id)
          
          prot_id = words[1].split(":")[1]
          if proteins_names.include? prot_id
            interactions.push(prot_id)
          end
        end
      end
    end
  end
  
  #remove redundancies
  
  protein.set_interact_with(interactions.uniq)
  if protein.interact_with
    puts protein.gene + " directly interacts with: " + protein.interact_with.inspect
    
  end
end

#This was my logic:  If A and B are protenins of the list and C is another protein (from the list or not),
#such as A interacts with C and C interacts with B, C will be in the array here called protein.set_interact_with
#of both A and B. In this circumstance, I will consider that A and B are part of a network
networks = []
proteins_interacted=[]
proteins.each do |prot1|
        networks.push (prot1)
    proteins.each do |prot2|
        if prot1 != prot2 && !prot1.interact_with.empty? && !prot2.interact_with.empty?
            prot1.interact_with.each do |prot_int|
                if prot2.name.include? prot_int
                    proteins_interacted.push(prot2)
                    break
                end
            end
        end
        
    end
    networks.push(Network.new(proteins_interacted))
end

#This will print all the networks with respective proteins, their respective interactors,
#GO terms of biological processes and KEGG pathways.
puts networks.inspect



