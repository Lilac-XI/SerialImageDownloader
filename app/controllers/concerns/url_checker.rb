module URLChecker extend ActiveSupport::Concern
    require "open-uri"
    require "trigram"
    
    def read_image_tags(url)
        OpenURI.open_uri(url).read.scan(/<img.*?>/)
    end

    def shape_image_tags(image_tags)
        image_urls = Array.new
        # タグを除去しurlに整形
        image_tags.each_with_index do |tag, i|
            if tag.include?("onerror=")
                image_urls[i] = tag.scan(/onerror="javascript:this.src=['"]http.*?['"]/).join
                image_urls[i].slice!(/onerror="javascript:this.src=['"]/)
                image_urls[i].slice!(/['"]/)
            else
                image_urls[i] = tag.scan(/src="http.*?"/).join
                image_urls[i].slice!(/src="/)
                image_urls[i].slice!(/"/)
            end
        end
        # 重複削除
        image_urls.uniq!
        return image_urls
    end

    def remove_died_url(urls)
        puts "remove start"
        urls.each_with_index do |url,i|
            begin
                OpenURI.open_uri(url,{:read_timeout => 1})
            rescue OpenURI::HTTPError, Net::ReadTimeout, Timeout::Error => e
                urls.delete_at(i)
                puts "delete #{url}"
            rescue => e
            end
        end
        puts "remove end"
        return urls
    end

    def split_similars(urls)
        puts "split similars start"
        similars = Array.new(urls.size-1)
        urls.each_with_index do |url,i|
            if i < similars.size
                similars[i] = Trigram.compare url, urls[i+1]
            end
        end

        l = 0
        sl = 0
        similar_urls = Array.new
        similars.each_with_index do |num,i|
            if i >= l
                if num < 0.7
                    similar_urls[sl] = urls[l..i]
                    sl = sl+1
                    l = i+1
                end
            end
        end

        similar_urls.delete_if do |urls|
            urls.size < 7
        end
        puts "split similars end"
        return similar_urls
    end
end