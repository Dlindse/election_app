class ArticleCandidate
    include Neo4j::ActiveRel
    # would accept :any instead of model constant
    from_class Article
    to_class Candidate
    
    # or
    # start_class Post
    # end_class Comment
    
    type 'Mentions'
    
    
    
end