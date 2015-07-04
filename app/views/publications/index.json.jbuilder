json.array!(@publications) do |publication|
  json.extract! publication, :id, :name, :url, :node_created
  json.url publication_url(publication, format: :json)
end
