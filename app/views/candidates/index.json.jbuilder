json.array!(@candidates) do |candidate|
  json.extract! candidate, :id, :name, :string, :node_created
  json.url candidate_url(candidate, format: :json)
end
