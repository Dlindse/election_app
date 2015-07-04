json.array!(@articles) do |article|
  json.extract! article, :id, :url, :node_created, :headline, :description, :pub_date
  json.url article_url(article, format: :json)
end
