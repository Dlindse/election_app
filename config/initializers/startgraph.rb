require 'rufus-scheduler'
require 'rest-client'
require 'nokogiri'
require 'json'
require 'date'

=begin

start = Time.now
nodesCreated = 0
relsCreated = 0

payload = []
scheduler = Rufus::Scheduler.new
scheduler.in '5m' do |update|

#scrape foxnews.com politics category
artis = []
(Date.parse('2015-06-25')..Date.parse('2015-07-04')).each{|date|
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
    (0..35).each {|page|
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



#make list of candidates in graph

graphCandis = Candidate.all



#make list of articles in graph with node id, headline and decsription
graphArtis = Article.all


#make array of just urls of the articles from the graph
artiUrls = []
graphArtis.each{|arti|
    artiUrls << arti[:url]
}

#get fox node

fox = Publication.find_by(name: "Fox News")


#create new article node if not already in graph
payload.each {|artiHsh|
    unless artiUrls.include?(artiHsh["url"])
        if artiHsh["alt_headline"] == String
            #create article node
            
            @node = Article.create(headline: artiHsh["headline"], alt_headline: artiHsh["alt_headline"], description: artiHsh["description"], url: artiHsh["url"], pub_date: artiHsh["date"].to_s[0..9], node_created: Time.now.to_s[0..9])
            nodesCreated += 1
            #connect article and publication node by Published rel
            PublicationArticle.create(from_node: fox, to_node: @node)
            relsCreated += 1
            #if candidate name appears in article headline or description
            #create mentions rel between article and candidate
            graphCandis.each {|candi|
                if @node[:headline].downcase.include?(candi[:name].downcase) || @node[:headline].downcase.include?(candi[:name].downcase.split[1]) || @node[:alt_headline].downcase.include?(candi[:name].downcase) || @node[:alt_headline].downcase.include?(candi[:name].downcase.split[1])|| @node[:description].downcase.include?(candi[:name].downcase) || @node[:description].downcase.include?(candi[:name].downcase.split[1])
                    name = candi[:name]
                    find = Candidate.find_by(name: name)
                    ArticleCandidate.create(from_node: @node, to_node: find )
                    relsCreated += 1				
                end
            }
            else
            #create article node
            
            @node = Article.create(headline: artiHsh["headline"], description: artiHsh["description"], url: artiHsh["url"], pub_date: artiHsh["date"].to_s[0..9], node_created: Time.now.to_s[0..9])
            nodesCreated += 1
            #connect article and publication node by Published rel
            PublicationArticle.create(from_node: fox, to_node: @node)
            relsCreated += 1
            #if candidate name appears in article headline or description
            #create mentions rel between article and candidate
            graphCandis.each {|candi|
                if @node[:headline].downcase.include?(candi[:name].downcase) || @node[:headline].downcase.include?(candi[:name].downcase.split[1]) || @node[:description].downcase.include?(candi[:name].downcase) || @node[:description].downcase.include?(candi[:name].downcase.split[1])
                    name = candi[:name]
                    find = Candidate.find_by(name: name)
                    ArticleCandidate.create(from_node: @node, to_node: find )
                    relsCreated += 1				
                end
            }		
        end			
    end
}

puts "Script created #{nodesCreated} nodes and #{relsCreated} rels in #{Time.now-start} seconds."

update.unschedule


end

=end