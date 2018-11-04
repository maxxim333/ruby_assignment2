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
  #IDs de proteinas del gen
  accessions_uri = URI("http://togows.org/entry/ebi-uniprot/#{gene}/accessions.json")
  
  accessions_text = Net::HTTP.get_response(accessions_uri)
  gene_prot_names = JSON.parse(accessions_text.body).flatten
  
  #GO terms de cada gen. This has a lot of info in form of array of arrays
  #but everything is in 0 and GO terms are written in a field called GO
  go_uri = URI("http://togows.org/entry/ebi-uniprot/#{gene}/dr.json") #2
  go_text = Net::HTTP.get_response(go_uri)
  go_terms = JSON.parse(go_text.body)[0]["GO"]
  #puts go_terms
  #terms.push(Protein.new(go_terms[0][0]))
  
  
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

proteins_names = proteins_names.flatten

puts "<=====================================================>"

#Interactions. The proteins have a code in IntAct. I want to pick the code of each
#of the proteins then go to the psicquic database and retreive the proteins it
#interacts with. In that database, there is a uniprotkb of the query protein folowed
#by the interacting one, so I have to pick only the interacting one, which will
#be always on the right side, or the second one (regexp will not work here because both begin by uniprotkb)

#These are direct interactions
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

#Find second level interactions. If A and B are protenins of the list
# and C is another protein, such as A interacts with C and C interacts
#with B, C will be in the array here called protein.set_interact_with
#of A and B

#proteins.each do |interaction|
 # if protein.interact_with[0].include? protein.interact_with[1]
  #  puts "There is a second level interaction" + protein.interact_with[1]
  #else
   # puts "no second level interaction"
  #end
#end
puts interactions[0]

#x = [1, 2, 4]
#y = [5, 2, 4]
#intersection = (x & y)
#num = intersection.length
#puts "There are #{num} numbers common in both arrays. Numbers are #{intersection}"



#Second level. Now here there will be the first and second level intereactions.
#Second level interactions will be added if there is a protein common between those
#interacting with the target protein AND any of the other proteins direct interactors
#(stored in interactions array)
interactions_second = []
proteins.each do |protein|
  protein.name.each do |name|
    interact_uri = URI("http://togows.org/entry/ebi-uniprot/#{name}/dr.json")
    interact_text = Net::HTTP.get_response(interact_uri).body
    data = JSON.parse(interact_text)
    int_act = data[0]["IntAct"]
    int_acts = 0
    if int_act
      int_act.each do |int|
        protein_inter_address = URI("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{int[0]}")
        protein_inter_text = Net::HTTP.get_response(protein_inter_address).body
        proteins_inter_line = protein_inter_text.split("\n").select{|x| /^uniprotkb/.match x}
        proteins_inter_line.each do |line|
          words = line.split("\t")
          prot_id = words[0].split(":")[1]
          if interactions.include? prot_id
            interactions_second.push(prot_id)
          end
          prot_id = words[1].split(":")[1]
          if interactions.include? prot_id
            interactions_second.push(prot_id)
          end
        end
      end
    end
  end
  
  #remove redundancies
  protein.set_interact_with(interactions_second.uniq)
  if protein.interact_with
    puts protein.gene + " interacts with: " + protein.interact_with.inspect
  end
end



puts "<=====================================================>"

puts interactions_second.to_a

#This allows me to see how many times a protein appears as an interactor and I sort them
howmanytimes = interactions_second.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
puts howmanytimes
howmanytimes_sorted = howmanytimes.sort_by { |id, numberoftimes| numberoftimes }.to_h
howmanytimes_sorted = howmanytimes_sorted.to_a.reverse.to_h
puts howmanytimes_sorted

#The network of protein interaction will be defined by many interactions, direct of indirect
#by a set of proteins. In my code, the more the protein is repeated in the hash below,
#the more it participates in the conections of the proteins from the innitial gene list
#I establish a cutoff of how many proteins I want to have in my network, search for genes
#that contain those proteins as their interactors and establish GO terms and KEGG
#pathways based on them
top10hash=[howmanytimes_sorted.to_a[0,5]]
puts top10hash


puts "<=====================================================>"

#Now rerieve the genes that have these top 10 interactors
genes_for_the_network=[]
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
          if top10hash.include? prot_id
            genes_for_the_network.push(prot_id)
          end
          prot_id = words[1].split(":")[1]
          if top10hash.include? prot_id
            genes_for_the_network.push(prot_id)
          end
        end
      end
    end
  end
  
  #remove redundancies
  protein.set_interact_with(genes_for_the_network.uniq)
  if protein.interact_with
    puts protein.gene + " belongs to the network and has GO: " + protein.go_hash.inspect + " has these KEGG pathways: " + protein.pathway_hash.inspect
  end

end

  

