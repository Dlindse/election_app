require 'rufus-scheduler'
require 'rest-client'
require 'nokogiri'
require 'json'
require 'date'



start = Time.now
nodesCreated = 0
relsCreated = 0

payload = []
scheduler = Rufus::Scheduler.new

#setup Neography client
@neo = Neography::Rest.new(ENV['GRAPHENEDB_URL'])


scheduler.in '30s' do |job|
    
    

    Publication.create(name: "CNN", url: "http://www.cnn.com/")
    Publication.create(name: "Fox News", url: "http://www.foxnews.com/")
    



#make list of announced candidates
candidates = []
candiUrls = ["http://www.2016election.com/list-of-declared-republican-presidential-candidates/","http://www.2016election.com/list-of-declared-democratic-presidential-candidates/"]
candiUrls.each {|url|
    resp = RestClient.get(url, 'User-Agent' => 'Ruby')
    page = Nokogiri::HTML(resp)
    candis = page.xpath("//div[@class='vw-post-content clearfix']/p[3]").text.strip.split("\n")
    #more search query string manipulation than fox scraper v1
    candis.each{|candi| candidates << candi}
}

#make list of candidates in graph
graphCandis = []
@neo.get_nodes_labeled("Candidate").each{|candiHsh| graphCandis << candiHsh["data"]["name"]}

#create new candidate node if not already in graph
candidates.each {|candi|
    unless graphCandis.include?(candi)
    Candidate.create(name: candi, node_created: Time.now.to_s[0..9])
        nodesCreated += 1
    end
}


job.unschedule

end


