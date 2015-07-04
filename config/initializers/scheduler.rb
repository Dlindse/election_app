require 'rufus-scheduler'
require 'rest-client'
require 'nokogiri'
require 'json'
require 'date'
require 'neography'


start = Time.now
nodesCreated = 0
relsCreated = 0

payload = []
scheduler = Rufus::Scheduler.new





scheduler.in '5m' do



#scrape foxnews.com politics category
artis = []
(Date.parse('2015-06-25')..Date.parse('2015-07-03')).each{|date|
    @url = "http://www.foxnews.com/feeds/web/politics/component/latest-news/feed/json/?rows=50&callback=FX_LM&max_date=#{date}T18:18:14Z"
    #	@url = "http://www.foxnews.com/feeds/web/politics/component/latest-news/feed/json/?rows=50&callback=FX_LM&max_date=#{Time.now.to_s[0..9]}T18:18:14Z"
    @resp = RestClient.get(@url, 'User-Agent' => 'Ruby')
    @page = Nokogiri::HTML(@resp)
    @pagetext = @page.xpath("//body").text.strip
    @cleantextarr = []
    unless @pagetext == "null"
        @stripTextArr = @pagetext[@pagetext.rindex(/"docs":/)+7...-3].gsub("[","").gsub("]","").split("},{")##.gsub("\\","")
        @stripTextArr.each{|result|
            if result.include?("content_type")
                @firsturl = result.index(",\"url\":\"http:")
                unless result.index("\",\"", @firsturl+10) == nil
                    @nexturl = result.index("\",\"", @firsturl+10)
                    #puts @firsturl
                    #puts "%*%*%*%"
                    @cleantextarr << result[0..@nexturl].gsub("\"authors\":,","") #+ "}"# "{" +   #"{" + "}"
                end
            end
        }
        @cleantextarr[0][0] = ""
        @cleantextarr.each_with_index {|ting, i|
            if ting == @cleantextarr[-1]
                if ting.index(",\"section\":") == nil
                    @cleantextarr[i] = "{" + ting + "}"
                    else
                    @cleantextarr[i] = "{" + ting[0..(ting.index(",\"section\":")-1)] + "}"
                end
                else
                if ting.index(",\"section\":") == nil
                    @cleantextarr[i] = "{" + ting + "},"
                    else
                    @cleantextarr[i] = "{" + ting[0..(ting.index(",\"section\":")-1)] + "},"
                end
            end
        }
        
        @jsontext = "["
        @cleantextarr.each{|ting|
            if ting == @cleantextarr[-1]
                @jsontext += ting
                else
                @jsontext += ting
            end
        }
        @jsontext += "]"
        
        @json = JSON.load(@jsontext)
        @json.each{|article|
            artis << article
        }
        
    end
}

artis.each{|arti|
    if arti["title"].class == NilClass
        @hsh = {}
        @hsh["headline"] = arti["export_headline"]
        @hsh["description"] = arti["description"]
        @hsh["url"] = arti["url"]
        @hsh["date"] = arti["date"].to_s[0..9]
        @hsh["type"] = arti["content_type"]
        payload << @hsh
        elsif arti["export_headline"].class == NilClass
        @hsh = {}
        @hsh["headline"] = arti["title"]
        @hsh["description"] = arti["description"]
        @hsh["url"] = arti["url"]
        @hsh["date"] = arti["date"].to_s[0..9]
        @hsh["type"] = arti["content_type"]
        payload << @hsh
        elsif arti["title"] == arti["export_headline"]
        @hsh = {}
        @hsh["headline"] = arti["title"]
        @hsh["description"] = arti["description"]
        @hsh["url"] = arti["url"]
        @hsh["date"] = arti["date"].to_s[0..9]
        @hsh["type"] = arti["content_type"]
        payload << @hsh
        else
        @hsh = {}
        @hsh["headline"] = arti["title"]
        @hsh["alt_headline"] = arti["export_headline"]
        @hsh["description"] = arti["description"]
        @hsh["url"] = arti["url"]
        @hsh["date"] = arti["date"].to_s[0..9]
        @hsh["type"] = arti["content_type"]
        payload << @hsh
    end
}
#payload.each{|story|
#	puts story
#	puts ""
#}





#scrape foxnews.com categories: presidential, elections, republican-elections, democrat-elections
#{"/category/politics/republican-elections" => 384, "/category/politics/democrat-elections" => 1077, "/category/politics/Elections" => 1332, "/category/politics/presidential" => 1083}
#payload = []

cats = [1077, 1083, 1332, 384]#
cats.each{|cat|
    (0..25).each {|page|
        @url = "http://www.foxnews.com/category/fetch/#{cat}/page/#{page}"
        @resp = RestClient.get(@url, 'User-Agent' => 'Ruby')
        @page = Nokogiri::HTML(@resp)
        
        #clean page results
        @pagetext = @page.xpath("//body").text.strip
        unless @pagetext == "null"
            @stripTextArr = @pagetext[@pagetext.rindex(/"docs":/)+7...-3].gsub("[","").gsub("]","").split("},{")##.gsub("\\","")
            @stripTextArr[0] = ""
            @stripTextArr[-1].chomp!("}")
            @textArr = @stripTextArr.drop(1)
            @textArr.each_with_index {|result,i|
                @firsturl = result.index(",\"url\":\"http:")
                #puts "#{@firsturl} is a #{@firsturl.class}"
                @nexturl = result.index("\",\"", @firsturl+10)
                next if @nexturl.class == NilClass
                @textArr[i] = result[0..@nexturl]
            }
            
            #make clean json a ruby object
            @jsontext = "["
            @textArr.each{|item|
                @jsontext += "{"+item+"},\n"
            }
            @jsontext.chomp!(",\n")
            @json = JSON.load(@jsontext + "]")
            
            #Fox's storage structure to our storage structure
            @json.each {|ting|
                @hsh = {}
                @hsh["headline"] = ting["title"]
                @hsh["description"] = ting["description"]
                @hsh["url"] = ting["url"]
                @hsh["date"] = ting["date"]
                @hsh["type"] = ting["content_type"]
                payload << @hsh
            }
        end
    }
}

#initiate Neo4j client
@neo = Neography::Rest.new
@neo.add_node_auto_index_property("uuid") #set uuid auto-index

#make list of candidates in graph
graphCandis = []
@neo.get_nodes_labeled("Candidate").each{ |candiHsh|
    @hsh = {}
    cutnum = candiHsh["labels"][35..-1].index("/")
    @hsh["node_id"] = candiHsh["labels"][35..35+cutnum-1].to_i
    @hsh["name"] = candiHsh["data"]["name"]
    graphCandis << @hsh
}

#make list of articles in graph with node id, headline and decsription
graphArtis = []
@neo.get_nodes_labeled("Article").each { |artiHsh|
    @hsh = {}
    cutnum = artiHsh["labels"][35..-1].index("/")
    @hsh["node_id"] = artiHsh["labels"][35..35+cutnum-1].to_i
    @hsh["hl_and_des"] = artiHsh["data"]["headline"] + " " + artiHsh["data"]["description"]
    @hsh["url"] = artiHsh["data"]["url"]
    graphArtis << @hsh
}

#make array of just urls of the articles from the graph
artiUrls = []
graphArtis.each{|arti|
    artiUrls << arti['url']
}

#get node id of Fox News node
foxNodeCode = 0
@neo.get_nodes_labeled("Publication").each { |pub|
    if pub["data"]["name"] == "Fox News"
        cutnum = pub["labels"][35..-1].index("/")
        foxNodeCode += pub["labels"][35..35+cutnum-1].to_i
    end
}




#create new article node if not already in graph
payload.each {|artiHsh|
    unless artiUrls.include?(artiHsh["url"])
        if artiHsh["alt_headline"] == String
            #create article node
            @node = @neo.create_node("headline" => artiHsh["headline"], "alt_headline" => artiHsh["alt_headline"], "description" => artiHsh["description"], "url" => artiHsh["url"], "pub_date" => artiHsh["date"].to_s[0..9], "node_created" => Time.now.to_s[0..9])
            @neo.set_label(@node, "Article")
            nodesCreated += 1
            #connect article and publication node by Published rel
            pubNode = @neo.get_node(foxNodeCode)
            @neo.create_relationship("Published", pubNode, @node)
            relsCreated += 1
            #if candidate name appears in article headline or description
            #create mentions rel between article and candidate
            graphCandis.each {|candi|
                if @node["data"]["headline"].downcase.include?(candi["name"].downcase) || @node["data"]["headline"].downcase.include?(candi["name"].downcase.split[1]) || @node["data"]["alt_headline"].downcase.include?(candi["name"].downcase) || @node["data"]["alt_headline"].downcase.include?(candi["name"].downcase.split[1])|| @node["data"]["description"].downcase.include?(candi["name"].downcase) || @node["data"]["description"].downcase.include?(candi["name"].downcase.split[1])
                    @neo.create_relationship("Mentions", @node, candi["node_id"])
                    relsCreated += 1				
                end
            }
            else
            #create article node
            @node = @neo.create_node("headline" => artiHsh["headline"], "description" => artiHsh["description"], "url" => artiHsh["url"], "pub_date" => artiHsh["date"].to_s[0..9], "node_created" => Time.now.to_s[0..9])
            @neo.set_label(@node, "Article")
            nodesCreated += 1
            #connect article and publication node by Published rel
            pubNode = @neo.get_node(foxNodeCode)
            @neo.create_relationship("Published", pubNode, @node)
            relsCreated += 1
            #if candidate name appears in article headline or description
            #create mentions rel between article and candidate
            graphCandis.each {|candi|
                if @node["data"]["headline"].downcase.include?(candi["name"].downcase) || @node["data"]["headline"].downcase.include?(candi["name"].downcase.split[1]) || @node["data"]["description"].downcase.include?(candi["name"].downcase) || @node["data"]["description"].downcase.include?(candi["name"].downcase.split[1])
                    @neo.create_relationship("Mentions", @node, candi["node_id"])
                    relsCreated += 1				
                end
            }		
        end			
    end
}

puts "Script created #{nodesCreated} nodes and #{relsCreated} rels in #{Time.now-start} seconds."







end