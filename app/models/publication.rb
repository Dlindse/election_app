class Publication 
  include Neo4j::ActiveNode
  property :name, type: String
  property :url, type: String
  property :node_created, type: String

has_many :out, :published, rel_class: PublicationArticle

end
