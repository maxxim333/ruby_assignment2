# Class Network
class Network
    attr_accessor :proteins
    attr_accessor :pathways_dict
    attr_accessor :gos_dict
end


def initialize (proteins = "", pathways_dict = [], gos_dict = Hash.new)
    @proteins = proteins
    @pathways_dict = pathways_dict
    @gos_dict = gos_dict
    
end