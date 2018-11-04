class Protein 
  
  attr_accessor :gene
  attr_accessor :name
  attr_accessor :pathway_hash
  attr_accessor :go_hash
  attr_accessor :interact_with
  
  def initialize (gene = "", name = [], go_hash = Hash.new, pathway_hash = Hash.new, interact_with = [])
    @gene = gene
    @name = name
    @go_hash = go_hash
    @pathway_hash = pathway_hash
    @interact_with = interact_with
  end
  
  def set_interact_with(proteins)
    if proteins
      proteins.each do |protein|
        if !@name.include? protein
          @interact_with.push protein
        end
      end
    end
  end
  
end

