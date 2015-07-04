class PublicationArticle
    include Neo4j::ActiveRel
    # would accept :any instead of model constant
    from_class Publication
    to_class Article
    
    # or
    # start_class Post
    # end_class Comment
    
    type 'Published'
    

    
end