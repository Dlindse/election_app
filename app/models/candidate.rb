class Candidate 
  include Neo4j::ActiveNode
  property :name, type: String
  property :string, type: String
  property :node_created, type: String
  
  has_many :in, :mentions, rel_class: ArticleCandidate

end
