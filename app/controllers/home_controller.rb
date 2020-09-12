class HomeController < ApplicationController
    require "open-uri"
    require "trigram"
    require "rmagick"
    require "combine_pdf"
    require "fileutils"
    require "./app/lib/image_downloader"
    def home
        @donwload = true
    end

    def create
        url = params[:download_link]
        imagetags = OpenURI.open_uri(url).read.scan(/<img.*?>/)
        imagelinks = Array.new

        imagetags.each_with_index do |tag, i|
            if tag.include?("onerror=")
                imagelinks[i] = tag.scan(/onerror="javascript:this.src=['"]http.*?['"]/).join
                imagelinks[i].slice!(/onerror="javascript:this.src=['"]/)
                imagelinks[i].slice!(/['"]/)
            else
                imagelinks[i] = tag.scan(/src="http.*?"/).join
                imagelinks[i].slice!(/src="/)
                imagelinks[i].slice!(/"/)
            end
        end
        # 重複削除
        imagelinks.uniq!

        #接続不能を除去
        imagelinks.each_with_index do |link,i|
            begin
                puts link
                OpenURI.open_uri(link,{:read_timeout => 0.2})
            rescue OpenURI::HTTPError, Net::ReadTimeout => e
                imagelinks.delete_at(i)
                puts "delete #{link}"
            rescue => each_wi
            end
        end
        puts imagelinks

        similars = Array.new(imagelinks.size-1)
        imagelinks.each_with_index do |link,i|
            if i < similars.size
                similars[i] = Trigram.compare link, imagelinks[i+1]
            end
        end
        l = 0
        sl = 0
        similar_links = Array.new
        similars.each_with_index do |num,i|
            if i >= l
                if num < 0.7
                    similar_links[sl] = imagelinks[l..i]
                    sl = sl+1
                    l = i+1
                end
            end
        end
        similar_links.delete_if do |links|
            links.size < 7
        end
        
        targets =  similar_links.max
        
        image_files = Magick::ImageList.new()
        title = Magick::Image.read(targets[0])[0]
        image_downloader = ImageDownloader.new(title.x_resolution,title.y_resolution)
        puts "start"
        if targets.size > 50
            puts "Over 50 page mode."
            x_resolution = title.x_resolution
            y_resolution = title.y_resolution
            pdfs = Array.new
            num = 0
            targets.each_with_index do |link,i|
                begin
                    image = Magick::Image.read(link)[0]
                    if image.x_resolution != x_resolution || image.y_resolution != y_resolution
                        puts "#{i} resize"
                        image.x_resolution = x_resolution
                        image.y_resolution = y_resolution
                    end
                    puts link
                    image_files.push image
                    if (i != 0 && (i % 50 == 0)) || (i > 50 && i == targets.size-1)
                        image_files.write("results/result#{num}.pdf")
                        pdfs[num] = "results/result#{num}.pdf"
                        puts "save results/result#{num}.pdf"
                        num = num + 1
                        image_files = Magick::ImageList.new()
                        GC.start
                    end
                rescue => e
                    puts "エラー: #{e}"
                end
            end
            puts "combine pdf"
            result = CombinePDF.new
            pdfs.each do |pdf_link|
                result << CombinePDF.load(pdf_link)
            end
            result.save ("results/result.pdf")
            GC.start
        else
            puts "Under 50 page mode."
            x_resolution = title.x_resolution
            y_resolution = title.y_resolution
            targets.each_with_index do |link,i|
                
                begin
                    image = Magick::Image.read(link)[0]
                    if image.x_resolution != x_resolution || image.y_resolution != y_resolution
                        puts "#{i} resize"
                        image.x_resolution = x_resolution
                        image.y_resolution = y_resolution
                    end
                    # image = image_downloader.download_image(link)
                    puts link
                    image_files.push image
                rescue => e
                    puts "エラー: #{e}"
                end
            end
            puts "save pdf"
            image_files.write("results/result.pdf")
            GC.start
        end
        redirect_to action: :ready
    end

    def ready
    end

    def download
        filepath = Rails.root.join("results","result.pdf")
        puts filepath
        filename = "#{Date.today.to_time.strftime("%y-%m-%d-%H-%M-%S")}.pdf"
        stat = File::stat(filepath)
        puts stat.size
        send_file(filepath,filename: filename, length: stat.size)
    end
end