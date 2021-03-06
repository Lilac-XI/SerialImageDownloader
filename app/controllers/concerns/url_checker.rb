module URLChecker extend ActiveSupport::Concern
    require "open-uri"
    require 'net/https'
    require 'uri'
    require "trigram"
    require "parallel"
    require "timeout"

    def read_image_tags(url)
        OpenURI.open_uri(url).read.scan(/<img.*?>/)
    end

    def shape_image_tags(image_tags)
        image_urls = Array.new
        # タグを除去しurlに整形
        image_tags.each_with_index do |tag, i|
            image_urls[i] = tag.scan(/ src="http.*?"/).join
            image_urls[i].slice!(/ src="/)
            image_urls[i].slice!(/"/)
        end
        # 重複削除
        image_urls.uniq!
        image_urls.delete("")
        return image_urls
    end

    def split_similars(urls)
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
        return similar_urls
    end
end