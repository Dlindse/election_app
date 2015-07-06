class Article 
  include Neo4j::ActiveNode
  property :url, type: String
  property :node_created, type: String
  property :headline, type: String
  property :alt_headline, type: String
  property :description, type: String
  property :pub_date, type: String

has_one :in, :published, rel_class: PublicationArticle
has_many :out, :mentions, rel_class: ArticleCandidate

end
